# Stands in for Pushpress::Client so tests never hit the network.
class FakePushpress
  attr_reader :customer_calls, :class_calls

  def initialize(classes: [], reservations: {}, customers: {})
    @classes, @reservations, @customers = classes, reservations, customers
    @customer_calls = 0
    @class_calls = 0
  end

  attr_reader :created_customers

  def create_customer(**attrs)
    (@created_customers ||= []) << attrs
    "usr_fake#{@created_customers.size}"
  end

  def classes(from:, to:)
    @class_calls += 1
    @classes.select { |c| c["start"] >= from.to_i && c["start"] < to.to_i }
  end
  def reservations(class_id:) = @reservations.fetch(class_id, [])

  def customer(id)
    @customer_calls += 1
    @customers.fetch(id)
  end
end
