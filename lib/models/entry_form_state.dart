class EntryFormStateData {
  String activeFilter; // 'all', 'lena', 'dena'
  String txType; // 'diya' ya 'liya'
  String selectedPaymentMode;
  String? selectedTag; // Optional selection
  bool isAddAccordionOpen;
  dynamic selectedFriendKey; // Single Friend Selection (No Group Split)

  // By default 3 tags + runtime custom added tags
  List<String> availableTags;

  EntryFormStateData({
    this.activeFilter = 'all',
    this.txType = 'diya',
    this.selectedPaymentMode = 'UPI',
    this.selectedTag,
    this.isAddAccordionOpen = false,
    this.selectedFriendKey,
    List<String>? availableTags,
  }) : availableTags = availableTags ?? ['Personal', 'Business', 'College'];
}
