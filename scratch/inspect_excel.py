import openpyxl
import sys

try:
    wb = openpyxl.load_workbook('/Users/apple/Downloads/my apps/bx/مناطق المملكة (1).xlsx')
    sheet = wb.active
    for row in sheet.iter_rows(max_row=10, values_only=True):
        print(row)
except ImportError:
    print("openpyxl not found")
except Exception as e:
    print(f"Error: {e}")
