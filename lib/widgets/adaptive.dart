import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const double kWideScreenBreakpoint = 720;

bool isWideScreen(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kWideScreenBreakpoint;

/// Width the wide shell gives the chat list before the user drags the handle.
const double kChatListDefaultWidth = 360;

/// Narrowest the chat list can be dragged: just wide enough for the avatar
/// rail and the floating action button.
const double kChatListMinWidth = 72;

/// Below this width the search field is replaced by the plain list title.
const double kChatListSearchMinWidth = 280;

/// Below this width a chat tile keeps only its avatar.
const double kChatListAvatarOnlyWidth = 160;

/// Below this width a chat tile drops its subtitle but keeps the chat name.
const double kChatListSubtitleMinWidth = 240;

/// Below this width the floating action buttons drop their labels.
const double kChatListFabLabelMinWidth = 240;

/// Opens the chat [chatId] in a way that fits the current layout.
///
/// On a wide screen the two-pane shell is a single page, so opening a chat
/// swaps the right pane with [GoRouter.go] and leaves the chat list mounted.
/// On a narrow screen a chat is its own pushed page, so the list stays beneath
/// it and the back gesture works. Pushing a second shell page on a wide screen
/// would duplicate the shell's page key and crash the Navigator.
void openChatRoute(BuildContext context, int chatId, {int? focusMessageId}) {
  final location = focusMessageId == null || focusMessageId <= 0
      ? '/chat/$chatId'
      : '/chat/$chatId?message=$focusMessageId';
  if (isWideScreen(context)) {
    context.go(location);
  } else {
    context.push(location);
  }
}

/// True for the two locations that make up the two-pane shell: the chat list
/// (`/`) and an open chat (`/chat/:id`).
bool isHomeLocation(String location) =>
    location == '/' ||
    (location.startsWith('/chat/') && !location.substring(6).contains('/'));
