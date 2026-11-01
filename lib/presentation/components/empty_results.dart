import 'package:flutter/material.dart';


class EmptyResults extends StatelessWidget {
  const EmptyResults({super.key, required this.isFiltered, required this.onRetry, this.object});

  final bool isFiltered;
  final VoidCallback onRetry;
  final String? object;
  
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.inventory_2_outlined,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            isFiltered ? 
            'No hay coincidencias.' :
            'No hay elementos ${object! == '' ? '.' : 'en el ${object!}.'}',
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar carga'),
            ),
          ],
        ],
      ),
    ),
  );
}
