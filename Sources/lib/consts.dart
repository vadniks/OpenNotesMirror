/// Created by VadNiks on Jul 31 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: constant_identifier_names

const APP_NAME = 'OpenNotes',
  MAIN_PAGE_TITLE = APP_NAME,
  EDIT_PAGE_TITLE = 'Edit note',
  DRAW_PAGE_TITLE = 'Draw note',
  PACKAGE_NAME = 'com.sout.android.notes',
  VERSION = '3.1.0';

const ROUTE_MAIN = '/',
  ROUTE_EDIT = '/e',
  ROUTE_DRAW = '/d';

const ITEMS_FETCH_AMOUNT = 15,
  NUM_UNDEF = -1;

const EMPTY_TEXT = 'Empty',
  TITLE_STRING = 'Title',
  TEXT_STRING = 'Text';
const String EMPTY_STRING = '';

const SAVE = 'Save',
  DELETE = 'Delete',
  NOTE_DOESNT_EXIST_YET = 'This note doesn\'t exist yet',
  TEXTS_ARE_EMPTY = 'Text fields are empty',
  CREATE_REMINDER = 'Create reminder',
  ATTACH_NOTIFICATION = 'Attach a notification reminder',
  TIMED_NOTIFICATION = 'Set date & time to notify once',
  SCHEDULE_NOTIFICATION = 'Schedule notification appearing',
  NO_CHANGES_IN_NOTE = 'Title & text are identical to the existing one\'s. No need to update',
  ERROR_OCCURRED = 'An error occurred',
  REMINDER_IS_SET = 'Reminder has been already set',
  REMOVE_REMINDER = 'Remove reminder',
  REMINDER_IS_NOT_SET = 'Reminder is not set',
  SAVED = 'Saved',
  CHOOSE_DATE = 'Choose date for the reminder to appear',
  CHOOSE_TIME = 'Choose time for the reminder to appear',
  CHOOSE_DATE_2 = 'Choose initial date for the reminder to appear for the first time',
  CHOOSE_TIME_2 = 'Choose initial time for the reminder to appear for the first time',
  SET_PERIOD = 'Set a time period',
  WEEKS = 'Weeks',
  DAYS = 'Days',
  HOURS = 'Hours',
  MINUTES = 'Minutes',
  DONE = 'Done',
  WRONG_VALUE = 'Wrong value',
  WRONG_VALUES_ENTERED = 'Wrong or empty values entered',
  TIME_PERIOD_HINT = 'Reminder will continue repeating with the given period until you cancel it or reboot the device',
  CREATE = 'Create new note',
  DETAILS = 'Details',
  TIMED_OR_SCHEDULED_IS_NOT_SET = 'Timed or scheduled reminder is not set',
  SELECT_NOTE = 'Click on a note to select it',
  CHOOSE_COLOR = 'Choose color',
  COLOR_SET = 'Color will be set after note saving/updating',
  CURRENT_COLOR = 'Current color: ',
  SEARCH_BY_TITLE = 'Search by title',
  SEARCH_WHILE_CONFIGURING_WIDGET = 'Search is unavailable while configuring widget',
  NOT_FOUND = 'Not found',
  SEND = 'Send',
  ALREADY_CREATING_OR_EDITING = 'Already creating or editing note',
  DB_BACKED_UP = 'Current database is encrypted and so it has been backed up. New blank database will be created. Crypt options will be added in the future updates',
  CANT_POST_NOTIFICATIONS = 'Posting notifications feature hasn\'t been allowed therefore attached, timed and scheduled reminders will be unavailable',
  CANCELED = 'Canceled',
  ITEMS_SELECTED = ' items selected',
  ABOUT = 'About',
  NOTHING_SELECTED = 'Nothing is selected',
  SET_SORT_MODE = 'Set sort mode',
  CURRENT_SORT_MODE = 'Current sort mode is: ',
  SORT_BY_ID = 'Sort by identificator',
  SORT_BY_TITLE = 'Sort  by title',
  ASC = 'Ask',
  DESC = 'Desc',
  ASCENDING = 'Ascending',
  DESCENDING = 'Descending',
  SORT_ORDER = 'Sort order',
  TRIGGER_DATE = 'Trigger date',
  TRIGGER_TIME = 'Trigger time',
  PERIOD_DATE = 'Period date',
  PERIOD_TIME = 'Period time',
  PICK_DATE = 'Pick date',
  NOT_SET = '<not set>',
  PERIOD_DAYS = 'Period days',
  PERIOD_HOURS = 'Period hours',
  PERIOD_MINUTES = 'Period minutes',
  UNABLE_TO_SELECT_REMINDER = 'Unable to select note with created reminder',
  COPIED = 'Copied',
  UNSAVED = 'The note hasn\'t been saved',
  GO_BACK = 'Go back',
  INCORRECT_DATE_OR_TIME = 'Incorrect date or time set',
  INCORRECT_TRIGGER_OR_PERIOD = 'Incorrect trigger date/time or period values set',
  NOTIFICATION_WILL_APPEAR_AT = ', notification will appear at ',
  LOGO_ASCII = '''
   ____                   _   __      __           
  / __ \\____  ___  ____  / | / /___  / /____  _____
 / / / / __ \\/ _ \\/ __ \\/  |/ / __ \\/ __/ _ \\/ ___/
/ /_/ / /_/ /  __/ / / / /|  / /_/ / /_/  __(__  ) 
\\____/ .___/\\___/_/ /_/_/ |_/\\____/\\__/\\___/____/  
    /_/                                            
''',
  MONOSPACE_FONT = 'SourceCodePro',
  COPYRIGHT = 'This is an open-source, non-commercial software.',
  SOURCES_LOCATED_AT = 'Source codes are available at:\n',
  REPO_LINK = 'https://github.com/vadniks/OpenNotesMirror';

const APP_ICON = 'assets/icon_notes.png';
