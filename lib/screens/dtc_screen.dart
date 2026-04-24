import 'package:flutter/material.dart';
import '../data/dtc_codes.dart';

class DtcScreen extends StatefulWidget {
  final List<String> storedCodes;
  final bool isConnected;
  final Future<bool> Function()? onClearCodes;

  const DtcScreen({
    super.key,
    required this.storedCodes,
    required this.isConnected,
    this.onClearCodes,
  });

  @override
  State<DtcScreen> createState() => _DtcScreenState();
}

class _DtcScreenState extends State<DtcScreen> {
  String? selectedCode;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Always work with full DtcCode objects
    final List<DtcCode> displayedCodes = _buildCodeList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search DTC codes...',
              hintStyle: TextStyle(color: Colors.white),
              prefixIcon: Icon(Icons.search, color: const Color(0xFFE11D48)),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: const Color(0xFFE11D48)),
                      onPressed: () => setState(() {
                        searchQuery = '';
                        selectedCode = null;
                      }),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFE11D48),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() {
              searchQuery = v;
              if (v.isNotEmpty) {
                selectedCode = null; // Clear selection when searching
              }
            }),
          ),
        ),

        // Warning banner if codes stored
        if (widget.storedCodes.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red[900]?.withAlpha(77),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red[400], size: 20),
                const SizedBox(width: 8),
                Text(
                  'STORED TROUBLE CODES (${widget.storedCodes.length})',
                  style: TextStyle(
                    color: Colors.red[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (widget.isConnected && widget.onClearCodes != null)
                  TextButton.icon(
                    onPressed: () => _confirmClearCodes(context),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
                  ),
              ],
            ),
          ),

        // Code list or empty state
        Expanded(
          child: displayedCodes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Trouble Codes Found',
                        style: TextStyle(
                          color: const Color(0xFFE11D48),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your vehicle is running clean!',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: displayedCodes.length,
                  itemBuilder: (context, index) {
                    final dtc = displayedCodes[index];
                    return ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getSeverityColor(dtc.severity).withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            dtc.code.substring(0, 1),
                            style: TextStyle(
                              color: _getSeverityColor(dtc.severity),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        dtc.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                      subtitle: Text(
                        dtc.description,
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(dtc.severity).withAlpha(38),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              dtc.severity.toUpperCase(),
                              style: TextStyle(
                                color: _getSeverityColor(dtc.severity),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: const Color(0xFFE11D48)),
                        ],
                      ),
                      onTap: () => setState(() => selectedCode = dtc.code),
                    );
                  },
                ),
        ),

        // Detail bottom sheet
        if (selectedCode != null) _buildCodeDetail(context),
      ],
    );
  }

  /// Build list of DtcCode objects from stored codes or search
  List<DtcCode> _buildCodeList() {
    if (searchQuery.isEmpty) {
      // Show stored vehicle codes (mapped through database)
      return widget.storedCodes
          .map((code) => DtcDatabase.getCode(code))
          .toList();
    } else {
      // Show search results
      return DtcDatabase.search(searchQuery);
    }
  }

  Widget _buildCodeDetail(BuildContext context) {
    final dtc = DtcDatabase.getCode(selectedCode!);

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Color(0xFF510000),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Code header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(dtc.severity).withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dtc.code,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _getSeverityColor(dtc.severity),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dtc.system.toUpperCase(),
                          style: TextStyle(
                            color: const Color(0xFFE11D48),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(dtc.severity).withAlpha(51),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dtc.severity.toUpperCase(),
                          style: TextStyle(
                            color: _getSeverityColor(dtc.severity),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    dtc.description,
                    style: const TextStyle(
                      color: const Color(0xFFE11D48),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Possible Causes
                  Text(
                    'POSSIBLE CAUSES',
                    style: TextStyle(
                      color: const Color(0xFFE11D48),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...dtc.possibleCauses.map(
                    (cause) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.arrow_right,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cause,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Diagnostic Steps
                  Text(
                    'DIAGNOSTIC STEPS',
                    style: TextStyle(
                      color: const Color(0xFFE11D48),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dtc.diagnosticSteps,
                      style: TextStyle(
                        color: const Color(0xFFE11D48),
                        height: 1.6,
                      ),
                    ),
                  ),

                  // Unknown code notice
                  if (dtc.severity == 'unknown') ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[900]?.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange[900]?.withAlpha(77) ?? Colors.orange,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[400],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This code is not in our local database. Consult a service center for accurate diagnosis.',
                              style: TextStyle(
                                color: Colors.orange[300],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearCodes(BuildContext context) async {
    bool confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Clear DTCs?'),
            content: const Text(
              'This will clear all stored diagnostic trouble codes from your vehicle.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm && widget.onClearCodes != null) {
      await widget.onClearCodes!();
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'minor':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}
