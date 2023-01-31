/// Created by VadNiks on Aug 02 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
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
  static const _EXPORT_DATABASE_METHOD = 'exportDatabase'; // TODO: put in the DatabaseManager
  static const _IMPORT_DATABASE_METHOD = 'importDatabase';
  static const _CHANGE_THEME_METHOD = 'changeTheme';
  var _isDatabaseBeingExportedOrImported = false;
  var _isFabCollapsed = true;

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

    Timer.run(() { // TODO: move to didChangeDependencies
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

  Future<void> _resetList() async { // TODO: rename to clearList
    _items.clear();
    setState(() {
      _from = 0;
      _hasFetched = false;
    });
  }

  Future<void> _onDBModified(void _) async {
    await _resetList();
    await _loadItems(true);
  }

  void _launchPage(String which, Note? note) {
    if (!navigator.canPop())
      navigator.pushNamed(
        which,
        arguments: note
      );
  }

  void launchEditPage(Note? note) => _launchPage(ROUTE_EDIT, note);

  void launchCanvasPage(Note? note) => _launchPage(ROUTE_CANVAS, note); // TODO: make private or implement canvas state saving

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

    if (note?.canvas == true) { // cuz true? (true or null) != true
      showSnackBar(CANVAS_CANNOT_BE_IN_WIDGET);
      return;
    }

    final widgetId = _widgetId!;
    setState(() => _widgetId = null);
    kernel.reminderManager.setWidget(note?.id, widgetId);
  }

  Widget _makeItem(Note note, BuildContext context) => Material(child: ListTile(
    onLongPress: () => _isConfiguringWidget || _isSelecting ? null : setState(() {
      _isSelecting = true;
      note.reminderType == null
        ? _selectedIds.add(note.id!)
        : showSnackBar(UNABLE_TO_SELECT_REMINDER);
    }),
    onTap: () => _isSelecting
      ? _selectedIds.contains(note.id!) // TODO: this is really a shit code, although...
        ? setState(() => _selectedIds.remove(note.id!))
        : note.reminderType == null
          ? setState(() => _selectedIds.add(note.id!)) 
          : showSnackBar(UNABLE_TO_SELECT_REMINDER)
      : !_isConfiguringWidget
        ? note.canvas
          ? launchCanvasPage(note)
          : launchEditPage(note)
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
    final isReminder = note.reminderType != null;
    final isColorPresent = note.color != null;
    final isBinary = note.canvas;

    return !isReminder && !isColorPresent && !isBinary ? null : Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isReminder) Text(note.reminderType!.toString())
        else if (isBinary) const Text(CANVAS_FLAG),
        if (isColorPresent) Padding(
          padding: EdgeInsets.only(top: isReminder ? 5 : 0),
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
      && _controller.position.extentAfter >= 51
      || _isFetching
      || _isSearching) return;
    setState(() => _isFetching = true);

    final items = await kernel.dbManager.fetchNotes(_from, ITEMS_FETCH_AMOUNT);
    if (items.isNotEmpty) for (final item in items) setState(() => _items.add(item));

    setState(() {
      _isFetching = false;
      _from += ITEMS_FETCH_AMOUNT;
      _hasFetched = true;
    });
  }

  Future<void> _setSortMode(int which, bool order) async {
    popTimes(2);
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
          title: Text('$CURRENT_SORT_MODE${sortMode.a == 0 ? SORT_BY_ID : SORT_BY_TITLE}'), // TODO: put sort modes into enum
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
                  color: isLightTheme
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
      ),
      ListTile(
        title: const Text(EXPORT_DATABASE),
        onTap: () {
          navigator.pop();
          setState(() => _isDatabaseBeingExportedOrImported = true);
          kernel.interop.callKotlinMethod(_EXPORT_DATABASE_METHOD, null);
        },
      ),
      ListTile(
        title: const Text(IMPORT_FROM_DATABASE),
        onTap: () {
          navigator.pop();
          setState(() => _isDatabaseBeingExportedOrImported = true);
          kernel.interop.callKotlinMethod(_IMPORT_DATABASE_METHOD, null);
        },
      ),
      ListTile(
        title: const Text(CHANGE_THEME),
        subtitle: const Text(CHANGE_THEME_HINT),
        onTap: () {
          kernel.interop.callKotlinMethod(_CHANGE_THEME_METHOD, null);
          navigator.pop();
        }
      )
    ])
  );

  void onDatabaseExportedOrImported(bool successful) {
    setState(() => _isDatabaseBeingExportedOrImported = false);
    showSnackBar(successful ? DATABASE_EXPORTED_OR_IMPORTED : ERROR_OCCURRED);
    _refresh();
  }

  Widget _showDbExportingImportingStub() => Center(child: Column(children: const [
    LinearProgressIndicator(),
    Expanded(child: Center(child: Text(
      DATABASE_EXPORT_OR_IMPORT_IS_IN_PROGRESS,
      style: TextStyle(fontSize: 18),
    )))
  ]));

  void _deleteSelected() {
    if (_selectedIds.isEmpty) {
      showSnackBar(NOTHING_SELECTED);
      return;
    }

    final ids = <int>[..._selectedIds];
    setState(() {
      _selectedIds.clear();
      _isSelecting = false;
    });

    kernel.dbManager.deleteSelected(ids);
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
      actions: _isDatabaseBeingExportedOrImported ? null : [
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
    body: _isDatabaseBeingExportedOrImported ? _showDbExportingImportingStub() : _hasFetched && _items.isEmpty
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
    floatingActionButton: _isOperationInProcess || _isDatabaseBeingExportedOrImported ? null : SizedBox.expand(child: Stack(
      alignment: Alignment.bottomRight,
      children: [
        Positioned(
          bottom: 65,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: _isFabCollapsed ? 0 : 1,
            child: _isFabCollapsed ? null : SizedBox(
              width: 45,
              height: 45,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() => _isFabCollapsed = true);
                  launchEditPage(null);
                },
                child: const Icon(Icons.text_snippet),
              ),
            )
          ),
        ),
        Positioned(
          right: 65,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: _isFabCollapsed ? 0 : 1,
            child: SizedBox(
              width: 45,
              height: 45,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() => _isFabCollapsed = true);
                  if (!navigator.canPop()) navigator.pushNamed(ROUTE_CANVAS);
                },
                child: const Icon(Icons.draw),
              ),
            )
          ),
        ),
        InkWell(
          onLongPress: () => launchEditPage(null),
          child: FloatingActionButton(
            onPressed: () => setState(() => _isFabCollapsed = !_isFabCollapsed),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _isFabCollapsed ? 0 : 0.125,
              child: const Icon(Icons.add)
            ),
          ),
        )
      ]
    )),
  );
}
