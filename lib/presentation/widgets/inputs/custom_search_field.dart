import 'package:flutter/material.dart';

class CustomSearchWidget extends StatefulWidget {
  const CustomSearchWidget({
    super.key,
    this.onChanged,
    this.controller,
    this.onFilterTap,
    this.onAddTap,
    this.suggestions = const [],
    this.onSuggestionSelected,
  });

  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onFilterTap;
  final VoidCallback? onAddTap;
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionSelected;

  @override
  State<CustomSearchWidget> createState() => _CustomSearchWidgetState();
}

class _CustomSearchWidgetState extends State<CustomSearchWidget> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  var _query = '';
  var _hideSuggestions = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _query = _controller.text;
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  List<String> get _matchingSuggestions {
    final query = _query.trim().toLowerCase();
    if (_hideSuggestions || query.isEmpty || widget.suggestions.isEmpty) {
      return const [];
    }

    final matches = <String>[];
    final seen = <String>{};
    for (final suggestion in widget.suggestions) {
      final value = suggestion.trim();
      final key = value.toLowerCase();
      if (value.isEmpty || seen.contains(key) || !key.contains(query)) {
        continue;
      }

      seen.add(key);
      matches.add(value);
      if (matches.length == 6) break;
    }
    return matches;
  }

  void _handleChanged(String value) {
    setState(() {
      _query = value;
      _hideSuggestions = false;
    });
    widget.onChanged?.call(value);
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.collapsed(offset: suggestion.length);
    setState(() {
      _query = suggestion;
      _hideSuggestions = true;
    });
    widget.onSuggestionSelected?.call(suggestion);
    widget.onChanged?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _matchingSuggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 44.0,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(22.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: _handleChanged,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 17.0,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                      size: 20.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22.0),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 1.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              if (widget.onAddTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                  child: GestureDetector(
                    onTap: widget.onAddTap,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16.0,
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: widget.onFilterTap,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    color: Colors.blue,
                    size: 20.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).colorScheme.surface,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.search, size: 18),
                  title: Text(suggestion),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
