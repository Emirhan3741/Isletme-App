enum ExpenseCategory {
  rent,
  salary,
  bill,
  other,
  electricity,
  water,
  naturalGas,
  phone,
  internet,
  material,
  cleaning,
  advertising,
  tax,
  insurance,
  fuel,
  food,
  education,
  maintenance
}

String getExpenseCategoryIcon(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.rent:
      return '🏠';
    case ExpenseCategory.salary:
      return '💰';
    case ExpenseCategory.bill:
      return '🧾';
    case ExpenseCategory.other:
      return '💼';
    case ExpenseCategory.electricity:
      return '⚡';
    case ExpenseCategory.water:
      return '💧';
    case ExpenseCategory.naturalGas:
      return '🔥';
    case ExpenseCategory.phone:
      return '📞';
    case ExpenseCategory.internet:
      return '📶';
    case ExpenseCategory.material:
      return '📦';
    case ExpenseCategory.cleaning:
      return '🧹';
    case ExpenseCategory.advertising:
      return '📢';
    case ExpenseCategory.tax:
      return '📋';
    case ExpenseCategory.insurance:
      return '🛡️';
    case ExpenseCategory.fuel:
      return '⛽';
    case ExpenseCategory.food:
      return '🍽️';
    case ExpenseCategory.education:
      return '📚';
    case ExpenseCategory.maintenance:
      return '🔧';
  }
}

extension ExpenseCategoryExtension on ExpenseCategory {
  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}
