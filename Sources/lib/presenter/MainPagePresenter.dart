/// Created by VadNiks on Aug 02 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: curly_braces_in_flow_control_structures, constant_identifier_names

import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/Observable.dart';
import 'Presenters.dart';
import '../model/Pair.dart';
import '../model/database/DBModificationMode.dart';
import '../model/database/Note.dart';
import '../view/MainPage.dart';
import '../consts.dart';
import 'AbsPresenter.dart';
import 'package:meta/meta.dart';

@sealed
class MainPagePresenter extends AbsPresenter<MainPage> {
  final List<Note> _items = [];
  late ScrollController _controller;
  var _from = 0;
  var _isFetching = false;
  var _hasFetched = false;
  static final Observable<MainPagePresenter, void> _observable = Observable();
  int? _widgetId;
  TextEditingController? _searchController;
  final List<int> _selectedIds = [];
  var _isSelecting = false;
  var _currentOrder = false;

  bool get _isConfiguringWidget => _widgetId != null;

  bool get _isSearching => _searchController != null;

  static void observeMainPageLaunch(void Function(MainPagePresenter) observer, bool add) =>
    _observable.observe(observer, add);

  MainPagePresenter(Object kernel) : super(kernel, Presenters.MAIN);

  Future<void> handleSendText(String title, String text) async {
    if (!navigator.canPop())
      navigator.pushNamed(
        ROUTE_EDIT,
        arguments: [title, text]
      );
    else
      showSnackBar(ALREADY_CREATING_OR_EDITING);
  }

  Future<void> notifyDBBackedUp() async => showSnackBar(DB_BACKED_UP);

  Future<void> notifyCantPostNotifications() async => showSnackBar(CANT_POST_NOTIFICATIONS);

  @override
  void initState() {
    super.initState();
    kernel.dbManager.observeDBModification(_onDBModified, true);
    _controller = ScrollController()..addListener(() => _loadItems(false));
    _loadItems(true);
    Timer.run(() {
      _observable.notify(this, null);
      _observable.reset();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(() => _loadItems(false));
    kernel.dbManager.observeDBModification(_onDBModified, false);
    _observable.reset();
    _searchController?.removeListener(_onSearch);
  }

  Future<void> _resetList() async => setState(() {
    _items.clear();
    _from = 0;
    _hasFetched = false;
  });

  Future<void> _onDBModified(Pair<Note?, DBModificationMode> _) async {
    if (_isSearching || _isConfiguringWidget || _isSelecting) return;
    await _resetList();
    await _loadItems(true);
  }

  void launchEditPage(Note? note) {
    if (!navigator.canPop())
      navigator.pushNamed(
        ROUTE_EDIT,
        arguments: note
      );
  }

  bool get _isOperationInProcess => _isConfiguringWidget || _isSearching || _isSelecting;

  void _endOperation() {
    assert(_isOperationInProcess);
    if (_isConfiguringWidget) _selectForWidget(null);
    if (_isSearching) _search(true);
    if (_isSelecting) setState(() {
      _selectedIds.clear();
      _isSelecting = false;
    });
  }

  Future<void> _search(bool close) async {
    if (_isConfiguringWidget) {
      showSnackBar(SEARCH_WHILE_CONFIGURING_WIDGET);
      return;
    }
    setState(() => _searchController = close ? null : (TextEditingController()..addListener(_onSearch)));

    await _resetList();
    if (close) await _loadItems(true);
  }

  Future<void> _onSearch() async {
    final query = _searchController!.text;
    if (query.isEmpty) {
      setState(() => _items.clear());
      return;
    }

    await _resetList();

    setState(() => _isFetching = true);
    _items.addAll(await kernel.dbManager.searchByTitle(query));

    setState(() => _isFetching = false);
  }

  void configureWidget(int id) {
    setState(() => _widgetId = id);
    _widgetId = id;
  }

  void _selectForWidget(Note? note) {
    if (note?.reminderType != null) {
      showSnackBar(REMINDER_IS_SET);
      return;
    }

    final widgetId = _widgetId!;
    setState(() => _widgetId = null);
    kernel.reminderManager.setWidget(note?.id, widgetId);
  }

  Widget _makeItem(Note note, BuildContext context) => Material(child: ListTile(
    onLongPress: () => setState(() {
      _isSelecting = true;
      note.reminderType == null ? _selectedIds.add(note.id!) : showSnackBar(UNABLE_TO_SELECT_REMINDER);
    }),
    onTap: () => _isSelecting
      ? _selectedIds.contains(note.id!)
        ? setState(() => _selectedIds.remove(note.id!))
        : note.reminderType == null 
          ? setState(() => _selectedIds.add(note.id!)) 
          : showSnackBar(UNABLE_TO_SELECT_REMINDER)
      : !_isConfiguringWidget
        ? launchEditPage(note)
        : _selectForWidget(note),
    title: Text(
      note.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis
    ),
    subtitle: Text(
      note.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis
    ),
    trailing: _makeTrailingForListTile(note),
    leading: !_selectedIds.contains(note.id!) ? null : const Icon(Icons.check),
  ));

  Widget? _makeTrailingForListTile(Note note) {
    final isTypePresent = note.reminderType != null;
    final isColorPresent = note.color != null;

    return !isTypePresent && !isColorPresent ? null : Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isTypePresent) Text(note.reminderType!.toString()),
        if (isColorPresent) Padding(
          padding: EdgeInsets.only(top: isTypePresent ? 5 : 0),
          child: SizedBox(
            width: 25.0,
            height: 25.0,
            child: ColoredBox(color: Color(note.color!.value!))
          )
        )
      ],
    );
  }

  Future<void> _loadItems(bool firstTIme) async {
    if (!firstTIme
      && _controller.position.extentAfter >= 30
      || _isFetching
      || _isSearching) return;
    setState(() => _isFetching = true);

    final items = await kernel.dbManager.fetchNotes(_from, ITEMS_FETCH_AMOUNT);
    if (items.isNotEmpty) setState(() => _items.addAll(items));

    setState(() {
      _isFetching = false;
      _from += ITEMS_FETCH_AMOUNT;
      _hasFetched = true;
    });
  }

  Future<void> _setSortMode(int which, bool order) async {
    navigator.pop();
    navigator.pop();
    await kernel.dbManager.setSortMode(which, order);
    _refresh();
  }

  Future<void> _showSortModeMenu() async => kernel.dbManager.fetchSortMode().then((sortMode) {
    _currentOrder = sortMode.b;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(builder: (_, stateSetter) => Column(children: [
        makeDividerForBottomSheet(),
        ListTile(
          title: Text('$CURRENT_SORT_MODE${sortMode.a == 0 ? SORT_BY_ID : SORT_BY_TITLE}'),
          trailing: TextButton(
            child: Text(
              _currentOrder ? DESC : ASC,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
            onPressed: () => stateSetter(() => _currentOrder = !_currentOrder),
          )
        ),
        makeDividerForBottomSheet(),
        ListTile(
          title: const Text(SORT_BY_ID),
          onTap: () => _setSortMode(0, _currentOrder)
        ),
        ListTile(
          title: const Text(SORT_BY_TITLE),
          onTap: () => _setSortMode(1, _currentOrder)
        )
      ]))
    );
  });

  Future<void> _showMenu() async => showModalBottomSheet(
    context: context,
    builder: (_) => Column(children: [
      makeDividerForBottomSheet(),
      ListTile(
        title: const Text(SET_SORT_MODE),
        onTap: _showSortModeMenu,
      ),
      ListTile(
        title: const Text(ABOUT),
        onTap: () => () {
          navigator.pop();
          return false; // TODO: beautify this
        }() ? (){}() : showAboutDialog(
          context: context,
          applicationName: APP_NAME,
          applicationVersion: VERSION,
          applicationIcon: const Image(
            image: AssetImage(APP_ICON),
            width: 50,
            height: 50,
          ),
          applicationLegalese: COPYRIGHT,
          children: [Align(
            alignment: Alignment.bottomCenter,
            child: Column(children: [
              const Text(
                LOGO_ASCII,
                style: TextStyle(
                  fontSize: 8,
                  fontFamily: MONOSPACE_FONT,
                  fontFeatures: [FontFeature.tabularFigures()]
                )
              ),
              RichText(text: TextSpan(
                text: SOURCES_LOCATED_AT,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black54
                    : Colors.white70,
                  fontSize: 12
                ),
                children: [TextSpan(
                  text: REPO_LINK,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 12
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () async {
                    await Clipboard.setData(const ClipboardData(text: REPO_LINK));
                    showSnackBar(COPIED);
                  }
                )]
              ))
            ])
          )]
        ),
      )
    ])
  );

  Future<void> _deleteSelected() async { // TODO: check if selected contains reminders and if contains - forbid deleting # DONE - IMPOSSIBLE TO SELECT REMINDER
    if (_selectedIds.isEmpty) {
      showSnackBar(NOTHING_SELECTED);
      return;
    }

    final ids = <int>[..._selectedIds];
    setState(() {
      _selectedIds.clear();
      _isSelecting = false;
    });

    await kernel.dbManager.deleteSelected(ids);
    Timer.run(_refresh);
  }

  Future<void> _refresh() async {
    await _resetList();
    await _loadItems(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: !_isOperationInProcess ? null : IconButton(
        onPressed: () => _endOperation(),
        icon: const Icon(Icons.close)
      ),
      title: !_isSearching
        ? Text(
          !_isConfiguringWidget
            ? _isSelecting
              ? _selectedIds.length.toString() + ITEMS_SELECTED
              : MAIN_PAGE_TITLE
            : SELECT_NOTE
        )
        : SizedBox(child: TextFormField(
          keyboardType: TextInputType.text,
          autofocus: true,
          maxLines: 1,
          cursorColor: Colors.white70,
          controller: _searchController!,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 20
          ),
          decoration: const InputDecoration(
            hintText: SEARCH_BY_TITLE,
            hintStyle: TextStyle(color: Colors.white38)
          )
        )),
      actions: [
        if (_isSelecting) IconButton(
          onPressed: _deleteSelected,
          icon: const Icon(Icons.delete)
        ),
        if (!_isOperationInProcess) IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _search(false),
        ),
        if (!_isOperationInProcess) IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showMenu,
        )
      ],
    ),
    body: _hasFetched && _items.isEmpty
      ? Center(child: Text(
        !_isSearching ? EMPTY_TEXT : NOT_FOUND,
        style: const TextStyle(fontSize: 18))
      )
      : Column(children: [
      if (_isFetching) const LinearProgressIndicator(value: null),
      Expanded(child: RefreshIndicator(
        onRefresh: _refresh,
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        notificationPredicate: (notification) => notification.depth == 0 && !_isSearching,
        child: ListView.separated(
          controller: _controller,
          itemCount: _items.length,
          itemBuilder: (_, index) => _makeItem(_items[index], context),
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            thickness: 1
          ),
        ),
      ))
    ]),
    floatingActionButton: _isConfiguringWidget || _isSearching ? null : FloatingActionButton(
      onPressed: () => launchEditPage(null),
      tooltip: CREATE,
      child: const Icon(Icons.add),
    ),
  );
}
