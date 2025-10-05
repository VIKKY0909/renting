"use server"

import { createClient } from "@/lib/supabase/server"
import { revalidatePath } from "next/cache"

export async function createOrder(formData: FormData) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { success: false, error: "Unauthorized" }
  }

  const productId = formData.get("product_id") as string
  const rentalStartDate = formData.get("rental_start_date") as string
  const rentalEndDate = formData.get("rental_end_date") as string
  const selectedSize = formData.get("selected_size") as string
  const paymentMethod = formData.get("payment_method") as string || "card"

  // Get product details
  const { data: product, error: productError } = await supabase
    .from("products")
    .select("*, owner:profiles!products_owner_id_fkey(id)")
    .eq("id", productId)
    .single()

  if (productError || !product) {
    return { success: false, error: "Product not found" }
  }

  // Check availability
  const { data: isAvailable } = await supabase.rpc("check_product_availability", {
    product_id: productId,
    start_date: rentalStartDate,
    end_date: rentalEndDate,
  })

  if (!isAvailable) {
    return { success: false, error: "Product is not available for selected dates" }
  }

  // Calculate rental days
  const start = new Date(rentalStartDate)
  const end = new Date(rentalEndDate)
  const rentalDays = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1

  // Calculate total
  const rentalPrice = product.rental_price * rentalDays
  const securityDeposit = product.security_deposit
  const discount = 0 // Can add discount logic here
  const totalAmount = rentalPrice + securityDeposit - discount

  const orderData = {
    user_id: user.id,
    product_id: productId,
    owner_id: product.owner.id,
    rental_start_date: rentalStartDate,
    rental_end_date: rentalEndDate,
    rental_days: rentalDays,
    rental_price: rentalPrice,
    security_deposit: securityDeposit,
    discount,
    total_amount: totalAmount,
    selected_size: selectedSize,
    status: "pending",
    payment_status: "pending",
    payment_method: paymentMethod,
  }

  const { data, error } = await supabase.from("orders").insert(orderData).select().single()

  if (error) {
    console.error("[v0] Error creating order:", error)
    return { success: false, error: error.message }
  }

  revalidatePath("/profile/orders")
  return { success: true, order: data }
}

export async function createMultiItemOrder(formData: FormData) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { success: false, error: "Unauthorized" }
  }

  const itemCount = parseInt(formData.get("itemCount") as string)
  const paymentMethod = formData.get("payment_method") as string || "card"
  const totalAmount = Number.parseFloat(formData.get("total_amount") as string)

  const ordersToInsert = []

  for (let i = 0; i < itemCount; i++) {
    const productId = formData.get(`item_${i}_productId`) as string
    const rentalStartDate = formData.get(`item_${i}_rentalStartDate`) as string
    const rentalEndDate = formData.get(`item_${i}_rentalEndDate`) as string
    const selectedSize = formData.get(`item_${i}_selectedSize`) as string
    const rentalPricePerItem = Number.parseFloat(formData.get(`item_${i}_rentalPrice`) as string)
    const securityDepositPerItem = Number.parseFloat(formData.get(`item_${i}_securityDeposit`) as string)
    const rentalDays = parseInt(formData.get(`item_${i}_rentalDays`) as string)

    // Get product details
    const { data: product, error: productError } = await supabase
      .from("products")
      .select("*, owner:profiles!products_owner_id_fkey(id)")
      .eq("id", productId)
      .single()

    if (productError || !product) {
      return { success: false, error: `Product not found for item ${i + 1}` }
    }

    // Check availability
    const { data: isAvailable } = await supabase.rpc("check_product_availability", {
      product_id: productId,
      start_date: rentalStartDate,
      end_date: rentalEndDate,
    })

    if (!isAvailable) {
      return { success: false, error: `Product "${product.title}" is not available for selected dates` }
    }

    // Calculate total for this item
    const itemRentalPrice = rentalPricePerItem * rentalDays
    const itemTotalAmount = itemRentalPrice + securityDepositPerItem

    ordersToInsert.push({
      user_id: user.id,
      product_id: productId,
      owner_id: product.owner.id,
      rental_start_date: rentalStartDate,
      rental_end_date: rentalEndDate,
      rental_days: rentalDays,
      rental_price: itemRentalPrice,
      security_deposit: securityDepositPerItem,
      discount: 0,
      total_amount: itemTotalAmount,
      selected_size: selectedSize,
      status: "pending",
      payment_status: "paid",
      payment_method: paymentMethod,
    })
  }

  const { data, error } = await supabase.from("orders").insert(ordersToInsert).select()

  if (error) {
    console.error("[v0] Error creating order:", error)
    return { success: false, error: error.message }
  }

  revalidatePath("/profile/orders")
  return { success: true, orders: data }
}

export async function getUserOrders() {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { orders: [], error: "Unauthorized" }
  }

  const { data, error } = await supabase
    .from("orders")
    .select(
      `
      *,
      product:products(
        id,
        title,
        images,
        category:categories!products_category_id_fkey(name)
      ),
      owner:profiles!orders_owner_id_fkey(id, full_name, phone)
    `,
    )
    .eq("user_id", user.id)
    .order("created_at", { ascending: false })

  if (error) {
    console.error("[v0] Error fetching orders:", error)
    return { orders: [], error: error.message }
  }

  return { orders: data || [], error: null }
}

export async function getOwnerOrders() {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { orders: [], error: "Unauthorized" }
  }

  const { data, error } = await supabase
    .from("orders")
    .select(
      `
      *,
      product:products(
        id,
        title,
        images,
        category:categories!products_category_id_fkey(name)
      ),
      user:profiles!orders_user_id_fkey(id, full_name, phone, city, state)
    `,
    )
    .eq("owner_id", user.id)
    .order("created_at", { ascending: false })

  if (error) {
    console.error("[v0] Error fetching owner orders:", error)
    return { orders: [], error: error.message }
  }

  return { orders: data || [], error: null }
}

export async function getOrderById(id: string) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { order: null, error: "Unauthorized" }
  }

  const { data, error } = await supabase
    .from("orders")
    .select(
      `
      *,
      product:products(
        *,
        category:categories!products_category_id_fkey(name, slug)
      ),
      owner:profiles!orders_owner_id_fkey(id, full_name, phone, email, city, state),
      user:profiles!orders_user_id_fkey(id, full_name, phone, email, city, state, pincode)
    `,
    )
    .eq("id", id)
    .single()

  if (error) {
    console.error("[v0] Error fetching order:", error)
    return { order: null, error: error.message }
  }

  // Check if user has access to this order
  if (data.user_id !== user.id && data.owner_id !== user.id) {
    return { order: null, error: "Unauthorized" }
  }

  return { order: data, error: null }
}

export async function updateOrderStatus(orderId: string, status: string) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { success: false, error: "Unauthorized" }
  }

  // Get order to check ownership
  const { data: order } = await supabase.from("orders").select("owner_id, user_id").eq("id", orderId).single()

  if (!order) {
    return { success: false, error: "Order not found" }
  }

  // Only owner or user can update status
  if (order.owner_id !== user.id && order.user_id !== user.id) {
    return { success: false, error: "Unauthorized" }
  }

  const { data, error } = await supabase.from("orders").update({ status }).eq("id", orderId).select().single()

  if (error) {
    console.error("[v0] Error updating order status:", error)
    return { success: false, error: error.message }
  }

  revalidatePath("/profile/orders")
  revalidatePath(`/orders/${orderId}`)
  return { success: true, order: data }
}

export async function updatePaymentStatus(orderId: string, paymentStatus: string) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { success: false, error: "Unauthorized" }
  }

  const { data, error } = await supabase
    .from("orders")
    .update({ payment_status: paymentStatus })
    .eq("id", orderId)
    .eq("user_id", user.id)
    .select()
    .single()

  if (error) {
    console.error("[v0] Error updating payment status:", error)
    return { success: false, error: error.message }
  }

  revalidatePath("/profile/orders")
  revalidatePath(`/orders/${orderId}`)
  return { success: true, order: data }
}

export async function cancelOrder(orderId: string) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { success: false, error: "Unauthorized" }
  }

  const { data, error } = await supabase
    .from("orders")
    .update({ status: "cancelled" })
    .eq("id", orderId)
    .eq("user_id", user.id)
    .select()
    .single()

  if (error) {
    console.error("[v0] Error cancelling order:", error)
    return { success: false, error: error.message }
  }

  revalidatePath("/profile/orders")
  return { success: true, order: data }
}
