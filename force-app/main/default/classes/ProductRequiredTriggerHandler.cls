public with sharing class ProductRequiredTriggerHandler {

    public static void invokeProductRequest(List<ProductRequired> productRequiredNewList) {
        ProductRequestGenerator.createProductRequest(productRequiredNewList);
    }
}