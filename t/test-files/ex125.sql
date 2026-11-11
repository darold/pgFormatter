-- Align multiline groups whose first expression starts on the opening line.
SELECT id FROM orders WHERE active
  AND (status IN ('pending', 'ready') OR (SELECT COUNT(*) FROM orders) > 1)
  AND (customer_id IS NULL OR EXISTS (SELECT 1 FROM customers WHERE customers.id = orders.customer_id));
