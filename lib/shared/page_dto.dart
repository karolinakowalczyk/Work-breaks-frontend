class PageDto<T> {
  List<T> content;
  int totalPages;

  PageDto(this.content, this.totalPages);
}
