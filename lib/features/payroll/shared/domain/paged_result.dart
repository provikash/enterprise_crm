class PageQuery {
  final int page;
  final int pageSize;
  final String? search;
  final String? sort;
  final Map<String, String> filters;

  const PageQuery({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.sort,
    this.filters = const {},
  }) : assert(page > 0),
       assert(pageSize > 0 && pageSize <= 200);

  PageQuery copyWith({
    int? page,
    int? pageSize,
    String? search,
    String? sort,
    Map<String, String>? filters,
    bool clearSearch = false,
  }) => PageQuery(
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
    search: clearSearch ? null : (search ?? this.search),
    sort: sort ?? this.sort,
    filters: filters ?? this.filters,
  );

  Map<String, String> toQueryParameters() => {
    'page': '$page',
    'pageSize': '$pageSize',
    if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
    if (sort != null && sort!.isNotEmpty) 'sort': sort!,
    ...filters,
  };
}

class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalItems;

  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
  });

  int get totalPages =>
      totalItems == 0 ? 0 : (totalItems + pageSize - 1) ~/ pageSize;
  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;
}
