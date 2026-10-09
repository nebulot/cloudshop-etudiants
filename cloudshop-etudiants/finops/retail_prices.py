#!/usr/bin/env python3
"""
TP3 - Interroger l'API publique Azure Retail Prices (aucune authentification requise).
Doc : https://learn.microsoft.com/rest/api/cost-management/retail-prices/azure-retail-prices

Exemples :
  python retail_prices.py vm Standard_B2s swedencentral francecentral germanywestcentral
  python retail_prices.py service "Azure Container Apps" swedencentral
"""
import sys
import requests

API = "https://prices.azure.com/api/retail/prices"
HOURS_PER_MONTH = 730  # convention Azure


def fetch(filter_expr: str, currency: str = "EUR") -> list[dict]:
    """Récupère toutes les pages de résultats pour un filtre OData."""
    items, url = [], API
    params = {"currencyCode": currency, "$filter": filter_expr}
    while url:
        r = requests.get(url, params=params, timeout=30)
        r.raise_for_status()
        data = r.json()
        items.extend(data.get("Items", []))
        url, params = data.get("NextPageLink"), None  # NextPageLink contient déjà les paramètres
    return items


def vm_prices(sku: str, regions: list[str]) -> None:
    print(f"\nPrix mensuels (Linux, {HOURS_PER_MONTH} h) pour {sku}\n")
    print(f"{'Région':<20}{'Modèle':<28}{'€/h':>10}{'€/mois':>12}")
    print("-" * 70)
    for region in regions:
        items = fetch(
            f"serviceName eq 'Virtual Machines' and armRegionName eq '{region}' "
            f"and armSkuName eq '{sku}'"
        )
        # On écarte Windows : la licence fausse la comparaison
        items = [i for i in items if "Windows" not in i["productName"]]
        rows = []
        for i in items:
            if i["type"] == "Consumption":
                model = "Spot" if "Spot" in i["skuName"] else (
                    "Low Priority" if "Low Priority" in i["skuName"] else "Pay-as-you-go")
                hourly = i["retailPrice"]
            elif i["type"] == "Reservation":
                # retailPrice = prix TOTAL de l'engagement : on le ramène à l'heure
                years = 1 if i.get("reservationTerm") == "1 Year" else 3
                model = f"Réservation {years} an(s)"
                hourly = i["retailPrice"] / (years * 12 * HOURS_PER_MONTH)
            else:
                continue
            rows.append((model, hourly))
        for model, hourly in sorted(rows, key=lambda r: -r[1]):
            print(f"{region:<20}{model:<28}{hourly:>10.4f}{hourly * HOURS_PER_MONTH:>12.2f}")
        print()


def service_prices(service: str, region: str) -> None:
    items = fetch(f"serviceName eq '{service}' and armRegionName eq '{region}' and type eq 'Consumption'")
    print(f"\n{len(items)} compteurs pour '{service}' en {region}\n")
    for i in sorted(items, key=lambda x: x["meterName"]):
        print(f"{i['meterName'][:45]:<47}{i['retailPrice']:>12.6f} € / {i['unitOfMeasure']}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    if sys.argv[1] == "vm":
        vm_prices(sys.argv[2], sys.argv[3:] or ["swedencentral"])
    elif sys.argv[1] == "service":
        service_prices(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "swedencentral")
