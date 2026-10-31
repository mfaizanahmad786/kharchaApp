package com.kharcha.kharcha

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * local_auth needs a FragmentActivity to host the system biometric prompt,
 * so this extends FlutterFragmentActivity rather than FlutterActivity.
 */
class MainActivity : FlutterFragmentActivity()
