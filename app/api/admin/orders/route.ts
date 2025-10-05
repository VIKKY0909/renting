import { createClient } from "@/lib/supabase/server"
import { NextRequest, NextResponse } from "next/server"

// GET /api/admin/orders - Get all orders with admin details
export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient()
    
    // Check if user is admin
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('is_admin')
      .eq('id', user.id)
      .single()

    if (!profile?.is_admin) {
      return NextResponse.json({ error: 'Admin access required' }, { status: 403 })
    }

    const { searchParams } = new URL(request.url)
    const status = searchParams.get('status')
    const payment_status = searchParams.get('payment_status')
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '20')
    const offset = (page - 1) * limit

    let query = supabase
      .from('orders')
      .select(`
        *,
        customer:profiles!orders_user_id_fkey (
          id,
          full_name,
          email,
          phone,
          city,
          state
        ),
        owner:profiles!orders_owner_id_fkey (
          id,
          full_name,
          email,
          phone,
          city,
          state
        ),
        products!orders_product_id_fkey (
          id,
          title,
          images,
          rental_price,
          security_deposit
        ),
        status_updated_by_profile:profiles!orders_status_updated_by_fkey (
          id,
          full_name
        )
      `)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1)

    if (status) {
      query = query.eq('status', status)
    }

    if (payment_status) {
      query = query.eq('payment_status', payment_status)
    }

    const { data: orders, error, count } = await query

    if (error) {
      console.error('Error fetching orders:', error)
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ 
      orders: orders || [], 
      count: count || 0,
      page,
      limit,
      totalPages: Math.ceil((count || 0) / limit)
    })
  } catch (error) {
    console.error('Error in GET /api/admin/orders:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
