import 'package:get/get.dart';

class JobController extends GetxController {
  RxBool isLoading = false.obs;

  void setLoading(bool loading) {
    isLoading.value = loading;
  }
}
