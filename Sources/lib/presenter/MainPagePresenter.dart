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
import 'package:flutter/material.dart';
import '../model/Observable.dart';
import 'Presenter.dart';
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

  bool get _isConfiguringWidget => _widgetId != null;

  bool get _isSearching => _searchController != null;

  static void observeMainPageLaunch(void Function(MainPagePresenter) observer, bool add) =>
      _observable.observe(observer, add);

  MainPagePresenter(Object kernel) : super(kernel, Presenter.MAIN);

  Future<void> handleSendText(String title, String text) async {
    if (!Navigator.canPop(context))
      Navigator.pushNamed(
        context,
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
    _isFetching = true;
    _items.clear();
    _from = 0;
    _isFetching = false;
    _hasFetched = false;
  });

  Future<void> _onDBModified(Pair<Note?, DBModificationMode> _) async {
    if (_isSearching) return;
    await _resetList();
    await _loadItems(true);
  }

  void launchEditPage(Note? note) {
    if (!Navigator.canPop(context))
      Navigator.pushNamed(
        context,
        ROUTE_EDIT,
        arguments: note
      );
  }

  bool get _isOperationInProcess => _isConfiguringWidget || _isSearching;

  void _endOperation() {
    assert(_isOperationInProcess);
    if (_isConfiguringWidget) _selectForWidget(null);
    if (_isSearching) _search(true);
  }

  void _search(bool close) {
    if (_isConfiguringWidget) {
      showSnackBar(SEARCH_WHILE_CONFIGURING_WIDGET);
      return;
    }

    if (close) _searchController!.removeListener(_onSearch);
    setState(() => _searchController = close ? null
        : (TextEditingController()..addListener(_onSearch)));

    _resetList();
    if (close) _loadItems(true);
  }

  Future<void> _onSearch() async {
    _resetList();

    setState(() => _isFetching = true);
    final items = await kernel.dbManager.searchByTitle(_searchController!.text);
    _items.addAll(items);

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

  Widget _makeItem(int index, BuildContext context) {
    final note = _items[index];
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 5,
        horizontal: 5,
      ),
      child: Material(
        child: ListTile(
          onTap: () => !_isConfiguringWidget
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
          trailing: _makeTrailingForListTile(note)
        )
      ),
    );
  }

  Widget? _makeTrailingForListTile(Note note) {
    final type = note.reminderType != null
        ? Text(note.reminderType!.toString())
        : null;
    final color = note.color != null
        ? Padding(
          padding: EdgeInsets.only(top: type == null ? 0 : 5),
          child: SizedBox(
            width: 25.0,
            height: 25.0,
            child: ColoredBox(color: Color(note.color!.value!))
          )
        )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (type != null) type,
        if (color != null) color
      ],
    );
  }

  Future<void> _loadItems(bool firstTIme) async {
    if (!firstTIme && _controller.position.extentAfter >= 30 ||
        _isFetching) return;
    setState(() => _isFetching = true);

    final items = await kernel.dbManager.fetchNotes(_from, ITEMS_FETCH_AMOUNT);
    if (items.isNotEmpty) setState(() => _items.addAll(items));

    setState(() {
      _isFetching = false;
      _from += ITEMS_FETCH_AMOUNT;
      _hasFetched = true;
    });
  }

  Future<void> _refresh() async {
    _resetList();
    _loadItems(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: !_isOperationInProcess ? null : IconButton(
        onPressed: () => _endOperation(),
        icon: const Icon(Icons.close)
      ),
      title: !_isSearching
          ? Text(!_isConfiguringWidget ? MAIN_PAGE_TITLE : SELECT_NOTE)
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
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(false),
          ),
        IconButton(
          icon: const Icon(Icons.info),
          onPressed: () => showAboutDialog(
            context: context,
            applicationName: APP_NAME,
            applicationVersion: VERSION,
            applicationIcon: const Image(
              image: AssetImage(APP_ICON),
              width: 50,
              height: 50,
            ),
            applicationLegalese: COPYRIGHT,
            children: [
              const Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  LOGO_ASCII,
                  style: TextStyle(
                    fontSize: 8,
                    fontFamily: MONOSPACE_FONT,
                    fontFeatures: [
                      FontFeature.tabularFigures()
                    ]
                  )
                ),
              )
            ]
          ),
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                controller: _controller,
                itemCount: _items.length,
                itemBuilder: (_, index) => _makeItem(index, context)
              ),
            )
          ),
        ],
    ),
    floatingActionButton: _isConfiguringWidget ? null : FloatingActionButton(
      onPressed: () => launchEditPage(null),
      tooltip: CREATE,
      child: const Icon(Icons.add),
    ),
  );
}
