import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiwayatPeminjamanPage extends StatefulWidget {
  final String userId;

  const RiwayatPeminjamanPage({super.key, required this.userId});

  @override
  State<RiwayatPeminjamanPage> createState() => _RiwayatPeminjamanPageState();
}

class _RiwayatPeminjamanPageState extends State<RiwayatPeminjamanPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? errorMessage;

  List<Map<String, dynamic>> loans = [];

  @override
  void initState() {
    super.initState();
    fetchLoans();
  }

  String _fmtDate(dynamic v) {
    try {
      if (v == null) return '-';
      final dt = DateTime.parse(v.toString());
      return dt.toIso8601String();
    } catch (_) {
      return v?.toString() ?? '-';
    }
  }

  String _jatuhTempo(Map<String, dynamic> loan) {
    if (loan['jatuh_tempo'] != null) {
      return _fmtDate(loan['jatuh_tempo']);
    }

    final tPinjam = loan['tanggal_pinjam'];
    try {
      if (tPinjam == null) return '-';
      final dt = DateTime.parse(
        tPinjam.toString(),
      ).add(const Duration(days: 7));
      return dt.toIso8601String();
    } catch (_) {
      return '-';
    }
  }

  Future<void> fetchLoans() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      final data = await supabase
          .from('loans')
          .select('id, status, tanggal_pinjam, book_id, books(id, judul)')
          .eq('user_id', widget.userId)
          .order('tanggal_pinjam', ascending: false);

      setState(() {
        loans = (data as List).cast<Map<String, dynamic>>();
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'Gagal mengambil riwayat: $e';
      });
    }
  }

  Future<void> kembalikanBuku(Map<String, dynamic> loan) async {
    final loanId = loan['id'];
    final bookId = loan['book_id'];

    if (loanId == null || bookId == null) return;

    try {
      await supabase
          .from('loans')
          .update({'status': 'kembali'})
          .eq('id', loanId);

      final bookRow = await supabase
          .from('books')
          .select('stok')
          .eq('id', bookId)
          .single();

      final stokNow = (bookRow['stok'] ?? 0) as int;

      await supabase
          .from('books')
          .update({'stok': stokNow + 1})
          .eq('id', bookId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buku berhasil dikembalikan')),
      );

      await fetchLoans();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengembalikan buku: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buku Saya')),
      body: RefreshIndicator(
        onRefresh: fetchLoans,
        child: Builder(
          builder: (context) {
            if (loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (errorMessage != null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: fetchLoans,
                    child: const Text('Coba lagi'),
                  ),
                ],
              );
            }

            if (loans.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [Text('Belum ada riwayat peminjaman.')],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: loans.length,
              itemBuilder: (context, index) {
                final loan = loans[index];
                final book = loan['books']; // hasil join
                final judul = (book is Map && book['judul'] != null)
                    ? book['judul'].toString()
                    : '-';

                final status = (loan['status'] ?? '-').toString();
                final jatuhTempo = _jatuhTempo(loan);

                final canReturn = status.toLowerCase() == 'dipinjam';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1626),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: ListTile(
                    title: Text(
                      judul,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: $status'),
                          Text('Jatuh Tempo: $jatuhTempo'),
                        ],
                      ),
                    ),
                    trailing: canReturn
                        ? TextButton(
                            onPressed: () => kembalikanBuku(loan),
                            child: const Text('Kembalikan'),
                          )
                        : const Text(
                            'Selesai',
                            style: TextStyle(color: Colors.white54),
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
