templates.removeWhere((t) => t.id == id);
    await _box.put('templates', jsonEncode(templates.map((t) => t.toJson()).toList()));
  }
}