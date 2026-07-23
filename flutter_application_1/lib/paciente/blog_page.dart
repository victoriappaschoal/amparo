import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final TextEditingController _buscaController =
      TextEditingController();

  bool carregando = false;
  String termoBusca = '';

  // Esta lista ficará vazia até a integração com o backend.
  List<ArtigoBlog> artigos = [];

  @override
  void initState() {
    super.initState();
    carregarArtigos();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> carregarArtigos() async {
    setState(() {
      carregando = true;
    });

    try {
      final resposta = await ApiService().getBlogArticles();

      if (!mounted) return;
      setState(() {
        artigos = [
          for (var i = 0; i < resposta.length; i++)
            ArtigoBlog.fromJson(resposta[i], i),
        ];
      });
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar os conteúdos.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  List<ArtigoBlog> get artigosFiltrados {
    if (termoBusca.trim().isEmpty) {
      return artigos;
    }

    final busca = termoBusca.toLowerCase();

    return artigos.where((artigo) {
      return artigo.titulo.toLowerCase().contains(busca) ||
          artigo.categoria.toLowerCase().contains(busca) ||
          artigo.resumo.toLowerCase().contains(busca);
    }).toList();
  }

  void abrirArtigo(ArtigoBlog artigo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalheArtigoPage(
          artigo: artigo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = artigosFiltrados;

    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: vinho,
        ),
        title: Text(
          'Blog',
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: vinho,
          onRefresh: carregarArtigos,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    14,
                    24,
                    8,
                  ),
                  child: Text(
                    'Conteúdos para você',
                    style: GoogleFonts.playfairDisplay(
                      color: vinho,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    18,
                  ),
                  child: Text(
                    'Informações e orientações para o período pós-parto.',
                    style: TextStyle(
                      color: vinho.withOpacity(0.72),
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    20,
                  ),
                  child: TextField(
                    controller: _buscaController,
                    onChanged: (valor) {
                      setState(() {
                        termoBusca = valor;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar conteúdo',
                      prefixIcon: Icon(
                        Icons.search,
                        color: vinho,
                      ),
                      suffixIcon: termoBusca.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _buscaController.clear();

                                setState(() {
                                  termoBusca = '';
                                });
                              },
                              icon: Icon(
                                Icons.close,
                                color: vinho,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.90),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: BorderSide(
                          color: rosaMedio.withOpacity(0.55),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: BorderSide(
                          color: vinho,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (carregando)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: vinho,
                    ),
                  ),
                )
              else if (lista.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _estadoVazio(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    30,
                  ),
                  sliver: SliverList.separated(
                    itemCount: lista.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 16);
                    },
                    itemBuilder: (context, index) {
                      return _cardArtigo(lista[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estadoVazio() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        30,
        30,
        30,
        70,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 105,
            height: 105,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.70),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: vinho,
              size: 55,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            termoBusca.isEmpty
                ? 'Nenhum conteúdo disponível'
                : 'Nenhum conteúdo encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            termoBusca.isEmpty
                ? 'Os conteúdos educativos serão exibidos aqui quando forem publicados.'
                : 'Tente buscar usando outro termo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho.withOpacity(0.68),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (termoBusca.isEmpty) ...[
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: carregarArtigos,
              icon: Icon(
                Icons.refresh,
                color: vinho,
              ),
              label: Text(
                'ATUALIZAR',
                style: TextStyle(
                  color: vinho,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: vinho,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardArtigo(ArtigoBlog artigo) {
    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.12),
      child: InkWell(
        onTap: () {
          abrirArtigo(artigo);
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              artigo.imageFileId == null
                  ? Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: rosaMedio.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Icon(
                        Icons.article_outlined,
                        color: vinho,
                        size: 32,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: SizedBox(
                        width: 62,
                        height: 62,
                        child: FutureBuilder(
                          future: ApiService()
                              .downloadFileBytes(artigo.imageFileId!),
                          builder: (context, snapshot) => snapshot.hasData
                              ? Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: rosaMedio.withOpacity(0.22),
                                ),
                        ),
                      ),
                    ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: vinho.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        artigo.categoria,
                        style: TextStyle(
                          color: vinho,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      artigo.titulo,
                      style: TextStyle(
                        color: vinho,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      artigo.resumo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: vinho.withOpacity(0.70),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          color: vinho.withOpacity(0.60),
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${artigo.tempoLeituraMinutos} min de leitura',
                          style: TextStyle(
                            color: vinho.withOpacity(0.60),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: vinho,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArtigoBlog {
  final int id;
  final String titulo;
  final String resumo;
  final String conteudo;
  final String categoria;
  final int tempoLeituraMinutos;
  final DateTime? publicadoEm;
  final String? imagemUrl;
  final String? imageFileId;

  const ArtigoBlog({
    required this.id,
    required this.titulo,
    required this.resumo,
    required this.conteudo,
    required this.categoria,
    required this.tempoLeituraMinutos,
    this.publicadoEm,
    this.imagemUrl,
    this.imageFileId,
  });

  /// Constrói a partir do JSON do backend (GET /blog).
  factory ArtigoBlog.fromJson(Map<String, dynamic> json, int indice) {
    final conteudo = (json['content'] ?? '').toString();
    final primeiraLinha = conteudo.split('\n').first.trim();
    final resumo = primeiraLinha.length > 140
        ? '${primeiraLinha.substring(0, 140)}...'
        : primeiraLinha;
    // ~180 palavras por minuto de leitura
    final minutos = (conteudo.split(' ').length / 180).ceil().clamp(1, 60);
    return ArtigoBlog(
      id: indice,
      titulo: (json['title'] ?? '').toString(),
      resumo: resumo,
      conteudo: conteudo,
      categoria: (json['category'] ?? 'Geral').toString(),
      tempoLeituraMinutos: minutos,
      publicadoEm: DateTime.tryParse((json['created_at'] ?? '').toString()),
      imagemUrl: null,
      imageFileId: json['image_file_id']?.toString(),
    );
  }

}

class DetalheArtigoPage extends StatelessWidget {
  final ArtigoBlog artigo;

  const DetalheArtigoPage({
    super.key,
    required this.artigo,
  });

  @override
  Widget build(BuildContext context) {
    const vinho = Color(0xFF87364E);
    const rosaClaro = Color(0xFFF8CCD2);

    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: vinho,
        ),
        title: const Text(
          'Conteúdo',
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          14,
          24,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              artigo.categoria,
              style: const TextStyle(
                color: vinho,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              artigo.titulo,
              style: GoogleFonts.playfairDisplay(
                color: vinho,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              artigo.resumo,
              style: TextStyle(
                color: vinho.withOpacity(0.72),
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            if (artigo.imageFileId != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: FutureBuilder(
                  future:
                      ApiService().downloadFileBytes(artigo.imageFileId!),
                  builder: (context, snapshot) => snapshot.hasData
                      ? Image.memory(
                          snapshot.data!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(height: 0),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                artigo.conteudo,
                style: TextStyle(
                  color: vinho.withOpacity(0.85),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: vinho.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: vinho,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Este conteúdo é educativo e não substitui a avaliação de um profissional de saúde.',
                      style: TextStyle(
                        color: vinho,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}