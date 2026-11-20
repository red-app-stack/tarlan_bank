import 'dart:convert';

import 'package:tarlan_bank/views/shared/custom_card.dart';
import 'package:tarlan_bank/views/shared/service_item.dart';
import 'package:tarlan_bank/views/shared/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../shared/formatters.dart';
import '../../services/secure_store.dart';
import '../../models/transaction_model.dart';

class TransactionDetailsController extends GetxController {
  Transaction transaction;
  final SecureStore secureStore = Get.find<SecureStore>();
  bool isFavorite = false;

  static const String favoritesKey = 'favorite_transfers';

  Future<List<Transaction>> getFavoriteTransfers() async {
    final favoritesJson = await secureStore.read(favoritesKey);
    if (favoritesJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      return decoded.map((json) => Transaction.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> saveFavoriteTransfer(Transaction transaction) async {
    List<Transaction> favorites = await getFavoriteTransfers();
    favorites.add(transaction);
    print(favorites.map((e) => e.toJson()).toList());
    await secureStore.write(
        favoritesKey, jsonEncode(favorites.map((e) => e.toJson()).toList()));
  }

  Future<void> removeFavoriteTransfer(String reference) async {
    List<Transaction> favorites = await getFavoriteTransfers();
    favorites.removeWhere((t) => t.reference == reference);
    await secureStore.write(
        favoritesKey, jsonEncode(favorites.map((e) => e.toJson()).toList()));
  }

  TransactionDetailsController(this.transaction);

  @override
  void onInit() async {
    super.onInit();
    await loadTransferState();
  }

  Future<void> loadTransferState() async {
    List<Transaction> favorites = await getFavoriteTransfers();
    for (Transaction element in favorites) {
      if (element.reference == transaction.reference) {
        isFavorite = true;
      }
    }
  }
}

class TransactionDetailsScreen extends StatefulWidget {
  TransactionDetailsScreen({super.key});

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final Transaction transaction = Get.arguments;

  final TransactionDetailsController controller =
      Get.put(TransactionDetailsController(Get.arguments as Transaction));

  Widget _buildUserAvatar(ThemeData theme, String? userName) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child:
          Text(getInitials(userName ?? ''), style: theme.textTheme.titleMedium),
    );
  }

  String _getStatusText(String type, String status) {
    switch (status) {
      case 'completed':
        return '${getTypeText(type)} успешно выполнен';
      case 'pending':
        return '${getTypeText(type)} в обработке';
      case 'failed':
        return '${getTypeText(type)} не выполнен';
      default:
        return '${getTypeText(type)} В обработке';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 24.0, right: 24, top: 12.0),
          child: Column(
            children: [
              buildHeader(context, 'Квитанция'),
              Card(
                shape: CustomBorder(),
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _getStatusText(transaction.type,
                                            transaction.status),
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        formatCurrency(transaction.amount,
                                            transaction.currency, 'ru_RU'),
                                        style: theme.textTheme.headlineLarge
                                            ?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundImage:
                                      AssetImage('assets/images/app_icon.png'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildUserAvatar(theme, transaction.toUserName),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      transaction.toUserName ?? 'Получатель',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    Text(
                                      transaction.toUserPhone != null
                                          ? '+7 ${transaction.toUserPhone}'
                                          : censorCardNumber(
                                              transaction.toAccount),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                _buildDetailRow(theme, 'Тип транзакции',
                                    getTypeText(transaction.type)),
                                const SizedBox(height: 4),
                                _buildDetailRow(theme, 'ID транзакции',
                                    transaction.reference),
                                const SizedBox(height: 4),
                                _buildDetailRow(theme, 'Дата и время',
                                    transaction.formattedCreatedAt),
                                const SizedBox(height: 4),
                                _buildDetailRow(theme, 'Комиссия',
                                    '0 ${transaction.currency}'),
                                const SizedBox(height: 4),
                                _buildDetailRow(theme, 'Отправитель',
                                    transaction.fromUserName ?? 'Неизвестно'),
                                const SizedBox(height: 4),
                                _buildDetailRow(theme, 'Счет отправителя',
                                    transaction.fromAccount),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SimpleCard(
                    child: Padding(
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ServiceItem(
                        iconData: Icons.share,
                        label: 'Поделиться',
                        iconSize: 24,
                      ),
                      ServiceItem(
                        iconData: Icons.repeat,
                        label: 'Повторить',
                        iconSize: 24,
                        onTap: () {
                          // ('deposit', 'withdrawal', 'phone_transfer', 'qr_transfer', 'currency_conversion',  'internal_transfer', 'card_transfer',  'swift_transfer'
                          // await Get.offAndToNamed('/main',
                          //     arguments: '/transfers');
                          Navigator.of(Get.context!).pop();
                          Navigator.of(Get.context!).pop();
                          switch (transaction.type) {
                            case 'phone_transfer':
                              Get.toNamed('/phoneTransfer',
                                  arguments: transaction);
                              break;
                            case 'internal_transfer':
                              Get.toNamed('/selfTransfer',
                                  arguments: transaction);
                              break;
                            case 'card_transfer':
                              Get.toNamed('/cardTransfer',
                                  arguments: transaction);
                              break;
                            case 'swift_transfer':
                              Get.toNamed('/swiftTransfer',
                                  arguments: transaction);
                              break;
                            case 'currency_conversion':
                              Get.toNamed('/convertation',
                                  arguments: transaction);
                              break;
                            case 'qr_transfer':
                              Get.toNamed('/qrTransfer',
                                  arguments: transaction);
                              break;
                          }
                        },
                      ),
                      ServiceItem(
                        iconData: Icons.cancel,
                        label: 'Отменить',
                        iconSize: 24,
                      ),
                      ServiceItem(
                          iconData: controller.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_outline,
                          label: controller.isFavorite
                              ? 'Из избранного'
                              : 'В избранное',
                          iconSize: 24,
                          onTap: () async {
                            if (controller.isFavorite) {
                              await controller.removeFavoriteTransfer(
                                  transaction.reference);
                            } else {
                              await controller
                                  .saveFavoriteTransfer(transaction);
                            }
                            controller.isFavorite = !controller.isFavorite;
                            setState(() {});
                          }),
                    ],
                  ),
                )),
              )
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class CustomBorder extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final Path path = Path();
    final double waveHeight = 6.0;
    final double waveWidth = 6.0;

    path.moveTo(rect.left, rect.top);

    bool up = true;
    for (double x = rect.left; x < rect.right; x += waveWidth) {
      if (up) {
        path.relativeQuadraticBezierTo(
          waveWidth / 2,
          -waveHeight,
          waveWidth,
          0,
        );
      } else {
        path.relativeQuadraticBezierTo(
          waveWidth / 2,
          waveHeight,
          waveWidth,
          0,
        );
      }
      up = !up;
    }

    path.lineTo(rect.right, rect.bottom);

    up = true;
    for (double x = rect.right; x > rect.left; x -= waveWidth) {
      if (up) {
        path.relativeQuadraticBezierTo(
          -waveWidth / 2,
          waveHeight,
          -waveWidth,
          0,
        );
      } else {
        path.relativeQuadraticBezierTo(
          -waveWidth / 2,
          -waveHeight,
          -waveWidth,
          0,
        );
      }
      up = !up;
    }

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class WavyLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();

    final waveHeight = 3.0;
    final wavelength = 10.0;

    path.moveTo(0, 0);

    for (double i = 0; i < size.width; i += wavelength) {
      path.quadraticBezierTo(
        i + (wavelength / 4),
        waveHeight,
        i + (wavelength / 2),
        0,
      );
      path.quadraticBezierTo(
        i + (wavelength * 3 / 4),
        -waveHeight,
        i + wavelength,
        0,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 8;
    const dashSpace = 5;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
