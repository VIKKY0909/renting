"use server"

import { createClient } from "@/lib/supabase/server"
import { revalidatePath } from "next/cache"

async function checkAdminAccess() {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { isAdmin: false, user: null }
  }

  const { data: profile } = await supabase.from("profiles").select("is_admin").eq("id", user.id).single()

  return { isAdmin: profile?.is_admin || false, user }
}

export async function getAdminStats() {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { stats: null, error: "Unauthorized" }
  }

  const supabase = await createClient()

  // Get counts with optimized queries
  const [
    { count: totalUsers },
    { count: totalProducts },
    { count: pendingProducts },
    { count: totalOrders },
    { count: activeOrders },
    { count: totalReviews },
    { count: pendingReviews },
  ] = await Promise.all([
    supabase.from("profiles").select("id", { count: "exact", head: true }),
    supabase.from("products").select("id", { count: "exact", head: true }),
    supabase.from("products").select("id", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("orders").select("id", { count: "exact", head: true }),
    supabase
      .from("orders")
      .select("id", { count: "exact", head: true })
      .in("status", ["pending", "confirmed", "shipped", "delivered"]),
    supabase.from("reviews").select("id", { count: "exact", head: true }),
    supabase.from("reviews").select("id", { count: "exact", head: true }).eq("status", "pending"),
  ])

  // Get revenue with optimized query
  const { data: orders } = await supabase
    .from("orders")
    .select("total_amount")
    .eq("status", "completed")
    .limit(1000) // Limit to prevent large data transfer

  const totalRevenue = orders?.reduce((sum, order) => sum + Number(order.total_amount), 0) || 0

  return {
    stats: {
      totalUsers: totalUsers || 0,
      totalProducts: totalProducts || 0,
      pendingProducts: pendingProducts || 0,
      totalOrders: totalOrders || 0,
      activeOrders: activeOrders || 0,
      totalReviews: totalReviews || 0,
      pendingReviews: pendingReviews || 0,
      totalRevenue,
    },
    error: null,
  }
}

export async function getAllUsers(filters?: { search?: string; limit?: number; offset?: number }) {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { users: [], count: 0, error: "Unauthorized" }
  }

  const supabase = await createClient()

  let query = supabase.from("profiles").select("id, email, full_name, phone, city, state, avatar_url, is_admin, email_confirmed_at, created_at", { count: "exact" })

  if (filters?.search) {
    query = query.or(`full_name.ilike.%${filters.search}%,email.ilike.%${filters.search}%`)
  }

  query = query.order("created_at", { ascending: false })

  if (filters?.limit) {
    query = query.limit(filters.limit)
  }

  if (filters?.offset) {
    query = query.range(filters.offset, filters.offset + (filters.limit || 10) - 1)
  }

  const { data, error, count } = await query

  if (error) {
    console.error("[v0] Error fetching users:", error)
    return { users: [], count: 0, error: error.message }
  }

  return { users: data || [], count: count || 0, error: null }
}

export async function getAllProducts(filters?: {
  status?: string
  search?: string
  limit?: number
  offset?: number
}) {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { products: [], count: 0, error: "Unauthorized" }
  }

  const supabase = await createClient()

  let query = supabase.from("products").select(
    `
      *,
      owner:profiles!products_owner_id_fkey(id, full_name, email),
      category:categories!products_category_id_fkey(id, name)
    `,
    { count: "exact" },
  )

  if (filters?.status) {
    query = query.eq("status", filters.status)
  }

  if (filters?.search) {
    query = query.or(`title.ilike.%${filters.search}%,description.ilike.%${filters.search}%`)
  }

  query = query.order("created_at", { ascending: false })

  if (filters?.limit) {
    query = query.limit(filters.limit)
  }

  if (filters?.offset) {
    query = query.range(filters.offset, filters.offset + (filters.limit || 10) - 1)
  }

  const { data, error, count } = await query

  if (error) {
    console.error("[v0] Error fetching products:", error)
    return { products: [], count: 0, error: error.message }
  }

  return { products: data || [], count: count || 0, error: null }
}

export async function approveProduct(productId: string) {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { success: false, error: "Unauthorized" }
  }

  const supabase = await createClient()

  const { error } = await supabase.from("products").update({ status: "approved" }).eq("id", productId)

  if (error) {
    console.error("[v0] Error approving product:", error)
    return { success: false, error: error.message }
  }

  revalidatePath("/admin/products")
  return { success: true }
}

export async function rejectProduct(productId: string) {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { success: false, error: "Unauthorized" }
  }

  const supabase = await createClient()

  const { error } = await supabase.from("products").update({ status: "rejected" }).eq("id", productId)

  if (error) {
    console.error("[v0] Error rejecting product:", error)
    return { success: false, error: error.message }
  }

  revalidatePath("/admin/products")
  return { success: true }
}

export async function getAllOrders(filters?: { status?: string; search?: string; limit?: number; offset?: number }) {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { orders: [], count: 0, error: "Unauthorized" }
  }

  const supabase = await createClient()

  let query = supabase.from("orders").select(
    `
      *,
      product:products(id, title, images),
      user:profiles!orders_user_id_fkey(id, full_name, email),
      owner:profiles!orders_owner_id_fkey(id, full_name, email)
    `,
    { count: "exact" },
  )

  if (filters?.status) {
    query = query.eq("status", filters.status)
  }

  if (filters?.search) {
    query = query.or(`product.title.ilike.%${filters.search}%,user.full_name.ilike.%${filters.search}%`)
  }

  query = query.order("created_at", { ascending: false })

  if (filters?.limit) {
    query = query.limit(filters.limit)
  }

  if (filters?.offset) {
    query = query.range(filters.offset, filters.offset + (filters.limit || 10) - 1)
  }

  const { data, error, count } = await query

  if (error) {
    console.error("[v0] Error fetching orders:", error)
    return { orders: [], count: 0, error: error.message }
  }

  return { orders: data || [], count: count || 0, error: null }
}

export async function getAllReviews(filters?: { status?: string; limit?: number; offset?: number }) {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { reviews: [], count: 0, error: "Unauthorized" }
  }

  const supabase = await createClient()

  let query = supabase.from("reviews").select(
    `
      *,
      product:products(id, title, images),
      user:profiles!reviews_user_id_fkey(id, full_name, avatar_url)
    `,
    { count: "exact" },
  )

  if (filters?.status) {
    query = query.eq("status", filters.status)
  }

  query = query.order("created_at", { ascending: false })

  if (filters?.limit) {
    query = query.limit(filters.limit)
  }

  if (filters?.offset) {
    query = query.range(filters.offset, filters.offset + (filters.limit || 10) - 1)
  }

  const { data, error, count } = await query

  if (error) {
    console.error("[v0] Error fetching reviews:", error)
    return { reviews: [], count: 0, error: error.message }
  }

  return { reviews: data || [], count: count || 0, error: null }
}

export async function getAllFAQs() {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { faqs: [], error: "Unauthorized" }
  }

  const supabase = await createClient()

  const { data, error } = await supabase
    .from("faqs")
    .select("*")
    .order("order_index", { ascending: true })

  if (error) {
    console.error("[v0] Error fetching FAQs:", error)
    return { faqs: [], error: error.message }
  }

  return { faqs: data || [], error: null }
}

export async function approveReview(reviewId: string) {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { success: false, error: "Unauthorized" }
  }

  const supabase = await createClient()

  const { error } = await supabase.from("reviews").update({ status: "approved" }).eq("id", reviewId)

  if (error) {
    console.error("[v0] Error approving review:", error)
    return { success: false, error: error.message }
  }

  revalidatePath("/admin/reviews")
  return { success: true }
}

export async function rejectReview(reviewId: string) {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { success: false, error: "Unauthorized" }
  }

  const supabase = await createClient()

  const { error } = await supabase.from("reviews").update({ status: "rejected" }).eq("id", reviewId)

  if (error) {
    console.error("[v0] Error rejecting review:", error)
    return { success: false, error: error.message }
  }

  revalidatePath("/admin/reviews")
  return { success: true }
}

export async function updateUserAdminStatus(userId: string, isAdmin: boolean) {
  const { isAdmin: currentUserIsAdmin } = await checkAdminAccess()

  if (!currentUserIsAdmin) {
    return { success: false, error: "Unauthorized" }
  }

  const supabase = await createClient()

  const { error } = await supabase.from("profiles").update({ is_admin: isAdmin }).eq("id", userId)

  if (error) {
    console.error("[v0] Error updating user admin status:", error)
    return { success: false, error: error.message }
  }

  revalidatePath("/admin/users")
  return { success: true }
}

export async function getAllEarnings(filters?: { status?: string; limit?: number; offset?: number }) {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { earnings: [], count: 0, error: "Unauthorized" }
  }

  const supabase = await createClient()

  let query = supabase.from("earnings").select(
    `
      *,
      owner:profiles!earnings_owner_id_fkey(id, full_name, email),
      order:orders(
        id,
        product:products(title)
      )
    `,
    { count: "exact" },
  )

  if (filters?.status) {
    query = query.eq("status", filters.status)
  }

  query = query.order("created_at", { ascending: false })

  if (filters?.limit) {
    query = query.limit(filters.limit)
  }

  if (filters?.offset) {
    query = query.range(filters.offset, filters.offset + (filters.limit || 10) - 1)
  }

  const { data, error, count } = await query

  if (error) {
    console.error("[v0] Error fetching earnings:", error)
    return { earnings: [], count: 0, error: error.message }
  }

  return { earnings: data || [], count: count || 0, error: null }
}

export async function processEarningPayout(earningId: string) {
  const { isAdmin } = await checkAdminAccess()

  if (!isAdmin) {
    return { success: false, error: "Unauthorized" }
  }

  const supabase = await createClient()

  const { error } = await supabase
    .from("earnings")
    .update({ status: "paid", payout_date: new Date().toISOString() })
    .eq("id", earningId)

  if (error) {
    console.error("[v0] Error processing payout:", error)
    return { success: false, error: error.message }
  }

  revalidatePath("/admin/earnings")
  return { success: true }
}
