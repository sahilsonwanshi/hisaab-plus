class EntryFormStateData {
  String activeFilter; // 'all', 'lena', 'dena'
  String txType; // 'diya' ya 'liya'
  String selectedPaymentMode;
  String? selectedTag; // Optional selection
  bool isAddAccordionOpen;
  final Set<dynamic> selectedFriendKeys;

  // By default sirf 3 tags + runtime custom added tags
  List<String> availableTags;

  EntryFormStateData({
    this.activeFilter = 'all',
    this.txType = 'diya',
    this.selectedPaymentMode = 'UPI',
    this.selectedTag,
    this.isAddAccordionOpen = false,
    Set<dynamic>? selectedFriendKeys,
    List<String>? availableTags,
  }) : selectedFriendKeys = selectedFriendKeys ?? {},
       availableTags = availableTags ?? ['Personal', 'Business', 'College'];
}
