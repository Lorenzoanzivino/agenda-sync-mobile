import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/colors.dart';
import '../viewmodels/calendar_cubit.dart';

void showCalendarManagementModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _CalendarManagementModal(),
  );
}

class _CalendarManagementModal extends StatefulWidget {
  @override
  State<_CalendarManagementModal> createState() => _CalendarManagementModalState();
}

class _CalendarManagementModalState extends State<_CalendarManagementModal> {
  bool _isCreating = true;
  final _nomeCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(30, 30, 30, bottomInset + 30),
          decoration: BoxDecoration(
            // COLORE MODIFICATO IN SHARED
            color: AppAtmospheres.sharedBg.withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5)),
          ),
          child: BlocConsumer<CalendarCubit, CalendarState>(
            listener: (context, state) {
              if (state is CalendarActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
                if (state.codeToShow != null) {
                  _showCodeDialog(context, state.codeToShow!);
                } else {
                  Navigator.pop(context);
                }
              } else if (state is CalendarError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent));
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Gestisci Condivisione", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Toggle Button
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isCreating = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isCreating ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Center(child: Text("Crea Nuovo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isCreating = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isCreating ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Center(child: Text("Usa Codice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  if (_isCreating) ...[
                    const Text("Nome Calendario (es. Io e Simona)", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nomeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(filled: true, fillColor: Colors.white.withValues(alpha: 0.1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                    ),
                  ] else ...[
                    const Text("Inserisci Codice di Invito", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _codeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(hintText: 'XYZ-123', hintStyle: TextStyle(color: Colors.white54), filled: true, fillColor: Colors.white.withValues(alpha: 0.1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                    ),
                  ],

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: state is CalendarLoading ? null : () {
                        if (_isCreating && _nomeCtrl.text.isNotEmpty) {
                          context.read<CalendarCubit>().createCalendar(_nomeCtrl.text);
                        } else if (!_isCreating && _codeCtrl.text.isNotEmpty) {
                          context.read<CalendarCubit>().joinCalendar(_codeCtrl.text);
                        }
                      },
                      child: state is CalendarLoading
                          ? const CircularProgressIndicator()
                          : const Text('CONFERMA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // COLORE MODIFICATO IN SHARED
        backgroundColor: AppAtmospheres.sharedBg,
        title: const Text("Codice Generato", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Condividi questo codice con l'altro utente:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            SelectableText(code, style: const TextStyle(color: Colors.cyanAccent, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copiato negli appunti!")));
            },
            child: const Text("COPIA", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("CHIUDI", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}