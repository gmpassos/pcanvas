int? tryParseInt(Object? o) {
  if (o == null) return null;
  if (o is int) return o;
  if (o is double) return o.toInt();
  return int.tryParse(o.toString());
}

int parseInt(Object? o) {
  if (o == null) throw ArgumentError("Null input!");
  if (o is int) return o;
  if (o is double) return o.toInt();
  return int.parse(o.toString());
}

num parseNum(Object? o) {
  if (o == null) throw ArgumentError("Null input!");
  if (o is num) return o;
  return num.parse(o.toString());
}

double? tryParseDouble(Object? o) {
  if (o == null) return null;
  if (o is double) return o;
  if (o is int) return o.toDouble();
  return double.tryParse(o.toString());
}

double parseDouble(Object? o) {
  if (o == null) throw ArgumentError("Null input!");
  if (o is double) return o;
  if (o is int) return o.toDouble();
  return double.parse(o.toString());
}

double max3(double a, double b, double c) {
  return (a > b) ? ((a > c) ? a : c) : ((b > c) ? b : c);
}

double min3(double a, double b, double c) {
  return (a < b) ? ((a < c) ? a : c) : ((b < c) ? b : c);
}
