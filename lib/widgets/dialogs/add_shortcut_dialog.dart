import 'package:aves/model/covers.dart';
import 'package:aves/model/entry.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/widgets/collection/thumbnail/raster.dart';
import 'package:aves/widgets/collection/thumbnail/vector.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/providers/media_query_data_provider.dart';
import 'package:aves/widgets/dialogs/item_pick_dialog.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import 'aves_dialog.dart';

class AddShortcutDialog extends StatefulWidget {
  final CollectionLens collection;
  final String defaultName;

  const AddShortcutDialog({
    required this.collection,
    required this.defaultName,
  });

  @override
  _AddShortcutDialogState createState() => _AddShortcutDialogState();
}

class _AddShortcutDialogState extends State<AddShortcutDialog> {
  final TextEditingController _nameController = TextEditingController();
  final ValueNotifier<bool> _isValidNotifier = ValueNotifier(false);
  AvesEntry? _coverEntry;

  CollectionLens get collection => widget.collection;

  Set<CollectionFilter> get filters => collection.filters;

  @override
  void initState() {
    super.initState();
    final entries = collection.sortedEntries;
    if (entries.isNotEmpty) {
      final coverEntries = filters.map(covers.coverContentId).where((id) => id != null).map((id) => entries.firstWhereOrNull((entry) => entry.contentId == id)).where((entry) => entry != null);
      _coverEntry = coverEntries.isNotEmpty ? coverEntries.first : entries.first;
    }
    _nameController.text = widget.defaultName;
    _validate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQueryDataProvider(
      child: Builder(
        builder: (context) {
          final shortestSide = context.select<MediaQueryData, double>((mq) => mq.size.shortestSide);
          final extent = (shortestSide / 3.0).clamp(60.0, 160.0);
          return AvesDialog(
            context: context,
            scrollableContent: [
              if (_coverEntry != null)
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(top: 16),
                  child: _buildCover(_coverEntry!, extent),
                ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.l10n.addShortcutDialogLabel,
                  ),
                  autofocus: true,
                  maxLength: 25,
                  onChanged: (_) => _validate(),
                  onSubmitted: (_) => _submit(context),
                ),
              ),
            ],
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _isValidNotifier,
                builder: (context, isValid, child) {
                  return TextButton(
                    onPressed: isValid ? () => _submit(context) : null,
                    child: Text(context.l10n.addShortcutButtonLabel),
                  );
                },
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildCover(AvesEntry entry, double extent) {
    return GestureDetector(
      onTap: _pickEntry,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          width: extent,
          height: extent,
          child: entry.isSvg
              ? VectorImageThumbnail(
                  entry: entry,
                  extent: extent,
                )
              : RasterImageThumbnail(
                  entry: entry,
                  extent: extent,
                ),
        ),
      ),
    );
  }

  Future<void> _pickEntry() async {
    final entry = await Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: ItemPickDialog.routeName),
        builder: (context) => ItemPickDialog(
          CollectionLens(
            source: collection.source,
            filters: filters,
          ),
        ),
        fullscreenDialog: true,
      ),
    );
    if (entry != null) {
      _coverEntry = entry;
      setState(() {});
    }
  }

  Future<void> _validate() async {
    final name = _nameController.text;
    _isValidNotifier.value = name.isNotEmpty;
  }

  void _submit(BuildContext context) => Navigator.pop(context, Tuple2<AvesEntry?, String>(_coverEntry, _nameController.text));
}
