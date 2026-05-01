class ApiRespon {
  final bool success;
  final String? message;
  final dynamic? data;
  final String? error;

  ApiRespon({required this.success, this.message, this.data, this.error});
}

class PaginationRespon {
  final List<dynamic> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  PaginationRespon({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });
}
