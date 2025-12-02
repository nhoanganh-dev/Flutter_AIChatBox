import 'package:chat_box/constants/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelSelectionDropdown extends StatefulWidget {
  final Function(String)? onModelChanged;

  const ModelSelectionDropdown({super.key, this.onModelChanged});

  @override
  State<ModelSelectionDropdown> createState() => _ModelSelectionDropdownState();
}

class _ModelSelectionDropdownState extends State<ModelSelectionDropdown> {
  String? selectedModel;
  final String _prefsKey = 'selected_chat_model';

  @override
  void initState() {
    super.initState();
    _loadSelectedModel();
  }

  Future<void> _loadSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedModel = prefs.getString(_prefsKey) ?? chatModels.keys.first;
    });
  }

  Future<void> _saveSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, model);
  }

  @override
  Widget build(BuildContext context) {
    if (selectedModel == null) {
      return const SizedBox(width: 48, height: 48);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: DropdownButton<String>(
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        selectedItemBuilder: (BuildContext context) {
          return chatModels.keys.map<Widget>((String key) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  chatModels[key]!,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            );
          }).toList();
        },
        value: selectedModel,
        isDense: true,
        dropdownColor: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        menuMaxHeight: 300, // Add this to prevent overflow
        items:
            chatModels.keys.map<DropdownMenuItem<String>>((String key) {
              return DropdownMenuItem<String>(
                value: key,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedModel == key)
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        )
                      else
                        const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            chatModels[key]!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            key,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              selectedModel = newValue;
            });
            _saveSelectedModel(newValue);
            widget.onModelChanged?.call(newValue);
          }
        },
      ),
    );
  }
}
