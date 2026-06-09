import 'package:tang0/src/core/context.dart';

import 'fake_platform.dart';

/// Build a [Tang0] runtime bound to a fake tab on [hub].
Tang0 ctx(FakeHub hub, String tabId) => Tang0(hub.tab(tabId).platform);
