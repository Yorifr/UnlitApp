// "Kendine bir not": kullanıcının kendi cümlesiyle yazdığı motivasyon notu.
//
// Neden hazır seçenek ("Çocuğum için" gibi) değil de serbest yazı? Hazır bir
// cümle kolayca suçluluğa dönüşebilir ("çocuğun seni izliyor" gibi). Kişinin
// KENDİ yazdığı cümle hem daha kişisel hem de daha az risklidir. Not, zor
// anda (erteleme ekranında) karşısına çıkar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import 'chunky.dart';

/// Yazı kutusunda sadece uygulamanın yazı tipinde (Nunito) olan harflere izin
/// verir: Latin + Türkçe harfler, rakamlar, noktalama ve ‘ ’ “ ” – — …
///
/// Neden? Web'de, yazı tipinde olmayan bir karakter (ör. emoji) çizilecek
/// olursa tarayıcı Google'dan yedek yazı tipi indirir. Bu, "uygulama
/// internete çıkmaz" sözümüzü bozar (bkz. CLAUDE.md → tuzaklar).
final noteInputFormatter = FilteringTextInputFormatter.allow(
  RegExp('[ -~ -ſ‘’“”–—…]'),
);

/// Notu yazma/düzenleme penceresini açar. Kaydedince profile yazılır.
Future<void> showReasonNoteDialog(BuildContext context, AppState state) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ReasonNoteDialog(state: state),
  );
}

class _ReasonNoteDialog extends StatefulWidget {
  const _ReasonNoteDialog({required this.state});
  final AppState state;

  @override
  State<_ReasonNoteDialog> createState() => _ReasonNoteDialogState();
}

class _ReasonNoteDialogState extends State<_ReasonNoteDialog> {
  late final _controller = TextEditingController(
    text: widget.state.profile.reasonNote ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(String? text) async {
    await widget.state.setReasonNote(text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasNote = widget.state.profile.reasonNote != null;
    return AlertDialog(
      title: const Text('Kendine bir not'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bunu neden yapıyorsun? Kendi cümlenle yaz; canın sigara '
              'istediğinde erteleme ekranında karşına çıksın. Not sadece bu '
              'telefonda kalır.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: UserProfile.maxNoteLength,
              textCapitalization: TextCapitalization.sentences,
              // Not tek paragraf: "Enter" yeni satır açmaz, klavyeyi kapatır.
              textInputAction: TextInputAction.done,
              inputFormatters: [noteInputFormatter],
              decoration: const InputDecoration(
                hintText:
                    'Örn. Merdivenleri nefes nefese kalmadan çıkmak '
                    'istiyorum.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (hasNote)
          TextButton(onPressed: () => _save(null), child: const Text('SİL')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('VAZGEÇ'),
        ),
        TextButton(
          onPressed: () => _save(_controller.text),
          child: const Text('KAYDET'),
        ),
      ],
    );
  }
}

/// Erteleme ekranındaki not kartı. Not varsa onu gösterir; yoksa yazmayı
/// önerir (isteğe bağlı, hiç yazmamak da serbest).
class ReasonNoteCard extends StatelessWidget {
  const ReasonNoteCard({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final note = state.profile.reasonNote;

    if (note == null) {
      return ChunkyCard(
        onTap: () => showReasonNoteDialog(context, state),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: c.purple, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kendine bir not yaz',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Bunu neden yapıyorsun? Kendi cümlen, zor anlarda burada '
              'karşına çıksın. İsteğe bağlı.',
              style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
            ),
          ],
        ),
      );
    }

    return ChunkyCard(
      color: c.purpleLight,
      borderColor: c.purple,
      onTap: () => showReasonNoteDialog(context, state),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote, color: c.purple, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kendine notun',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(note, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, color: c.textMuted, size: 20),
        ],
      ),
    );
  }
}
