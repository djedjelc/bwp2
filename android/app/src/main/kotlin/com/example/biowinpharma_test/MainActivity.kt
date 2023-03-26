package com.biowin.telepharmacie

import android.os.Bundle // Ajouter cette ligne pour importer la classe Bundle
import androidx.multidex.MultiDex
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MultiDex.install(this)
    }
}
