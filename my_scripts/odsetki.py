#!/usr/bin/env python3
import csv
import datetime
import sys

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} input_filename")
    sys.exit(1)

input_filename = sys.argv[1]

with open(input_filename) as csv_file:
    csv_reader = csv.DictReader(csv_file)
    payments = list(csv_reader)


# Input date for calculating interest (today)
input_date = datetime.datetime.now().date()

# Calculate interest for each payment
total_amount = 0
total_interest = 0
# https://poradnikprzedsiebiorcy.pl/-odsetki-ustawowe
interest_rate = 0.1225  # Example interest rate of 12% per annum

for payment in payments:
    required_payment_date = datetime.datetime.strptime(
        payment["required_payment_date"], "%Y-%m-%d"
    ).date()
    payment_amount = float(payment["payment_amount"])

    if input_date > required_payment_date:
        delay_days = (input_date - required_payment_date).days
        interest = (payment_amount * interest_rate * delay_days) / 365

        print(
            f"Płatność {payment_amount} PLN wymagana do dnia: {required_payment_date} jest opóźniona {delay_days} dni - {interest:.2f} PLN odsetek urzędowych."
        )
        total_amount = total_amount + payment_amount
        total_interest = total_interest + interest
print("Należność: ", total_amount, "Odsetki: ", round(total_interest, 2))
print("W sumie: ", round(total_amount + total_interest, 2))
