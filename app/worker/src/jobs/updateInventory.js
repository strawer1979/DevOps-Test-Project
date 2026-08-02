import logger from '../logger.js';

/**
 * Process inventory update job - simulates updating product inventory
 * after an order is placed
 */
export async function handleUpdateInventoryJob(job) {
  const { orderId, items } = job.data;

  logger.info(
    { orderId, items },
    'Processing inventory update job'
  );

  try {
    // Simulate inventory update delay
    await new Promise(resolve => setTimeout(resolve, 50));

    // In a real implementation, this would update the inventory in the database
    // For each item in the order, we would:
    // 1. Check if sufficient inventory exists
    // 2. Deduct the quantity from the product inventory
    // 3. Log any low stock warnings

    for (const item of items) {
      const { productId, quantity } = item;

      // Simulate inventory deduction
      logger.debug(
        { productId, quantity, orderId },
        'Inventory deducted for product'
      );

      // Check for low stock (simulated threshold of 10)
      const simulatedStockLevel = 100 - quantity;
      if (simulatedStockLevel < 10) {
        logger.warn(
          { productId, stockLevel: simulatedStockLevel },
          'Low stock warning'
        );
      }
    }

    logger.info(
      { orderId, itemCount: items.length },
      'Inventory updated successfully'
    );

    return {
      success: true,
      orderId,
      itemsUpdated: items.length,
      message: 'Inventory updated successfully'
    };
  } catch (error) {
    logger.error(
      { err: error, orderId, items },
      'Failed to process inventory update job'
    );
    throw error;
  }
}

export default handleUpdateInventoryJob;
