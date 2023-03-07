# frozen_string_literal: true

require 'terminal-table'

class PrintBill
  attr_accessor :total_price

  PRODUCTS = {
    'milk' => {
      'unit_price' => 3.97,
      'sell_amount' => {
        'items_count' => 3,
        'sale_price' => 5.0
      }
    },
    'bread' => {
      'unit_price' => 2.17,
      'sell_amount' => {
        'items_count' => 4,
        'sale_price' => 6.0
      }
    },
    'banana' => {
      'unit_price' => 0.99,
      'sell_amount' => {
        'items_count' => 1,
        'sale_price' => 0.55
      }
    },
    'apple' => {
      'unit_price' => 0.89,
      'sell_amount' => {
        'items_count' => 1,
        'sale_price' => 0.55
      }
    }
  }.freeze

  PRICES = PRODUCTS

  def initialize
    @total_price = {}
  end

  def all
    PRICES
  end

  def calc_unit_price(item)
    PRICES.dig(item, 'unit_price')
  end

  def is_sale_price?(item)
    return true unless PRICES.dig(item, 'sell_amount').empty?
  end

  def calc_sale_price(item)
    PRICES.dig(item, 'sell_amount', 'sale_price')
  end

  def count_offer_items(item)
    PRICES.dig(item, 'sell_amount', 'items_count')
  end

  def print_table(total)
    rows = []
    money = 0
    savings = 0
    total.each do |item, data|
      quantity = data['quantity']
      price = data['price']
      saved_amount = data['savings']
      savings += saved_amount
      money += price
      rows << [item.capitalize, quantity, price.round(2)]
    end
    puts Terminal::Table.new headings: %w[Item Quantity Price], rows: rows
    puts "Total price : $#{money.round(2)}"
    puts "You saved $#{savings.round(2)} today"
  end

  def print
    puts 'Please enter all the items purchased separated by a comma'
    items = gets.chomp.downcase
    items = items.delete(' ').split(',')
    frequency_hash = filter_product_items(items)
    total = final_total(frequency_hash)
    print_table(total)
  rescue StandardError
    puts "\n No Item matches"
  end

  private

  def filter_product_items(products)
    frequency_hash = Hash.new(0)
    products.each { |key| frequency_hash[key] += 1 }
    frequency_hash
  end

  def final_total(frequency_hash)
    frequency_hash.each do |name, quantity|
      final_price = calc_f_amount(name, quantity)
      savings = total_saved_amount(name, quantity, final_price)
      calc_t_amount(name, quantity, final_price, savings)
    end
    total_price
  end

  def items_are_within_offer?(name, quantity)
    items_count = count_offer_items(name)
    (quantity % items_count).zero?
  end

  def items_less_than_offer_count?(name, quantity)
    items_count = count_offer_items(name)
    quantity < items_count
  end

  def calc_t_amount(name, quantity, final_price, savings)
    total_price[name] = {
      'quantity' => quantity,
      'price' => final_price,
      'savings' => savings
    }
  end

  def calc_f_amount(name, quantity)
    if is_sale_price?(name)
      return discount_only(name, quantity) if items_are_within_offer?(name, quantity)
      return no_discount(name, quantity) if items_less_than_offer_count?(name, quantity)

      return discount_offered(name, quantity)
    end

    no_discount(name, quantity)
  end

  def discount_only(name, quantity)
    items_count = count_offer_items(name)
    sale_price = calc_sale_price(name)
    item_quantity = quantity / items_count
    item_quantity * sale_price
  end

  def no_discount(name, quantity)
    unit_price = calc_unit_price(name)
    unit_price * quantity
  end

  def discount_offered(name, quantity)
    unit_price = calc_unit_price(name)
    sale_price = calc_sale_price(name)
    items_count = count_offer_items(name)
    deduction = quantity % items_count
    items_with_offer = (quantity - deduction) / items_count
    (items_with_offer * sale_price) + (deduction * unit_price)
  end

  def total_saved_amount(name, quantity, final_price)
    unit_price = calc_unit_price(name)
    normal_price = unit_price * quantity
    normal_price - final_price
  end
end

calculations = PrintBill.new
calculations.print
