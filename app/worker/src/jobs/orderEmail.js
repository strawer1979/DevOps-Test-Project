import logger from '../logger.js';
import { query } from '../db.js';

/**
 * Process order email job - simulates sending order confirmation email
 * and updates order status in the database
 */
export async function handleOrderEmailJob(job) {
  const { orderId, customerEmail, orderDetails } = job.data;

  logger.info(
    { orderId, customerEmail, orderDetails },
    'Processing order email job'
  );

  try {
    // Simulate email sending delay
    await new Promise(resolve => setTimeout(resolve, 100));

    // Update order status in database
    const updateQuery = `
      UPDATE orders
      SET status = 'email_sent',
          updated_at = NOW()
      WHERE id = $1
      RETURNING id, status, updated_at
    `;

    const result = await query(updateQuery, [orderId]);

    if (result.rowCount === 0) {
      logger.warn({ orderId }, 'Order not found in database');
    } else {
      logger.info(
        { orderId, newStatus: result.rows[0].status },
        'Order status updated successfully'
      );
    }

    logger.info(
      { orderId, customerEmail },
      'Order confirmation email sent successfully'
    );

    return {
      success: true,
      orderId,
      customerEmail,
      message: 'Email sent and order status updated'
    };
  } catch (error) {
    logger.error(
      { err: error, orderId, customerEmail },
      'Failed to process order email job'
    );
    throw error;
  }
}

export default handleOrderEmailJob;
