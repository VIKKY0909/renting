"use client"

import { useState, useEffect } from "react"
import { 
  Clock, 
  CheckCircle, 
  XCircle, 
  Truck, 
  Package, 
  RotateCcw,
  CreditCard,
  MapPin,
  Calendar,
  User,
  Phone,
  Mail,
  AlertTriangle
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { toast } from "sonner"
import Image from "next/image"

interface Order {
  id: string
  rental_start_date: string
  rental_end_date: string
  rental_days: number
  rental_price: number
  security_deposit: number
  total_amount: number
  status: string
  payment_status: string
  tracking_number?: string
  admin_notes?: string
  customer_notes?: string
  pickup_address?: string
  delivery_address?: string
  pickup_scheduled_date?: string
  delivery_scheduled_date?: string
  return_scheduled_date?: string
  actual_pickup_date?: string
  actual_delivery_date?: string
  actual_return_date?: string
  shipping_cost: number
  late_fee: number
  damage_fee: number
  final_amount?: number
  refund_amount: number
  created_at: string
  customer: {
    id: string
    full_name: string
    email: string
    phone: string
    city: string
    state: string
  }
  owner: {
    id: string
    full_name: string
    email: string
    phone: string
    city: string
    state: string
  }
  products: {
    id: string
    title: string
    images: string[]
    rental_price: number
    security_deposit: number
  }
  status_updated_by_profile?: {
    id: string
    full_name: string
  }
}

interface OrderManagementProps {
  initialOrders?: Order[]
}

export function AdminOrderManagement({ initialOrders = [] }: OrderManagementProps) {
  const [orders, setOrders] = useState<Order[]>(initialOrders)
  const [loading, setLoading] = useState(false)
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null)
  const [activeTab, setActiveTab] = useState("pending")

  useEffect(() => {
    fetchOrders()
  }, [activeTab])

  const fetchOrders = async () => {
    setLoading(true)
    try {
      const response = await fetch(`/api/admin/orders?status=${activeTab === 'all' ? '' : activeTab}`)
      const data = await response.json()
      if (response.ok) {
        setOrders(data.orders || [])
      } else {
        toast.error('Failed to fetch orders')
      }
    } catch (error) {
      console.error('Error fetching orders:', error)
      toast.error('Error fetching orders')
    } finally {
      setLoading(false)
    }
  }

  const handleOrderAction = async (orderId: string, action: string, notes?: string) => {
    try {
      const response = await fetch(`/api/admin/orders/${orderId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: action,
          admin_notes: notes
        })
      })

      if (response.ok) {
        toast.success(`Order ${action} successfully`)
        fetchOrders()
        setSelectedOrder(null)
      } else {
        const error = await response.json()
        toast.error(error.error || 'Failed to update order')
      }
    } catch (error) {
      console.error('Error updating order:', error)
      toast.error('Error updating order')
    }
  }

  const getStatusBadge = (status: string) => {
    const statusConfig = {
      pending: { label: 'Pending', variant: 'secondary' as const, icon: Clock, color: 'text-yellow-600' },
      confirmed: { label: 'Confirmed', variant: 'default' as const, icon: CheckCircle, color: 'text-blue-600' },
      picked_up: { label: 'Picked Up', variant: 'default' as const, icon: Package, color: 'text-orange-600' },
      dispatched: { label: 'Dispatched', variant: 'default' as const, icon: Truck, color: 'text-purple-600' },
      delivered: { label: 'Delivered', variant: 'default' as const, icon: CheckCircle, color: 'text-green-600' },
      picked_up_for_return: { label: 'Picked Up for Return', variant: 'secondary' as const, icon: RotateCcw, color: 'text-orange-600' },
      returned: { label: 'Returned', variant: 'default' as const, icon: RotateCcw, color: 'text-blue-600' },
      completed: { label: 'Completed', variant: 'default' as const, icon: CheckCircle, color: 'text-green-600' },
      cancelled: { label: 'Cancelled', variant: 'destructive' as const, icon: XCircle, color: 'text-red-600' },
      rejected: { label: 'Rejected', variant: 'destructive' as const, icon: XCircle, color: 'text-red-600' }
    }

    const config = statusConfig[status as keyof typeof statusConfig] || statusConfig.pending
    const Icon = config.icon

    return (
      <Badge variant={config.variant} className="flex items-center gap-1">
        <Icon className={`h-3 w-3 ${config.color}`} />
        {config.label}
      </Badge>
    )
  }

  const getPaymentStatusBadge = (status: string) => {
    const config = {
      pending: { label: 'Pending', variant: 'secondary' as const, color: 'text-yellow-600' },
      paid: { label: 'Paid', variant: 'default' as const, color: 'text-green-600' },
      refunded: { label: 'Refunded', variant: 'default' as const, color: 'text-blue-600' }
    }

    const statusConfig = config[status as keyof typeof config] || config.pending

    return (
      <Badge variant={statusConfig.variant} className="flex items-center gap-1">
        <CreditCard className={`h-3 w-3 ${statusConfig.color}`} />
        {statusConfig.label}
      </Badge>
    )
  }

  const getStats = () => {
    const stats = {
      pending: orders.filter(o => o.status === 'pending').length,
      confirmed: orders.filter(o => o.status === 'confirmed').length,
      dispatched: orders.filter(o => o.status === 'dispatched').length,
      delivered: orders.filter(o => o.status === 'delivered').length,
      completed: orders.filter(o => o.status === 'completed').length,
      cancelled: orders.filter(o => o.status === 'cancelled').length,
      total: orders.length
    }
    return stats
  }

  const stats = getStats()

  const getNextStatus = (currentStatus: string) => {
    const statusFlow = {
      pending: 'confirmed',
      confirmed: 'picked_up',
      picked_up: 'dispatched',
      dispatched: 'delivered',
      delivered: 'picked_up_for_return',
      picked_up_for_return: 'returned',
      returned: 'completed'
    }
    return statusFlow[currentStatus as keyof typeof statusFlow]
  }

  if (loading && orders.length === 0) {
    return (
      <div className="space-y-6">
        <div className="text-center py-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
          <p className="mt-2 text-muted-foreground">Loading orders...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="font-serif text-2xl font-bold mb-2">Order Management</h2>
          <p className="text-muted-foreground">Track and manage rental orders</p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-6 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <Clock className="h-4 w-4 text-yellow-600" />
              <div>
                <p className="text-sm text-muted-foreground">Pending</p>
                <p className="text-2xl font-bold">{stats.pending}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-blue-600" />
              <div>
                <p className="text-sm text-muted-foreground">Confirmed</p>
                <p className="text-2xl font-bold">{stats.confirmed}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <Truck className="h-4 w-4 text-purple-600" />
              <div>
                <p className="text-sm text-muted-foreground">Dispatched</p>
                <p className="text-2xl font-bold">{stats.dispatched}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <Package className="h-4 w-4 text-green-600" />
              <div>
                <p className="text-sm text-muted-foreground">Delivered</p>
                <p className="text-2xl font-bold">{stats.delivered}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-green-600" />
              <div>
                <p className="text-sm text-muted-foreground">Completed</p>
                <p className="text-2xl font-bold">{stats.completed}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-purple-600" />
              <div>
                <p className="text-sm text-muted-foreground">Total</p>
                <p className="text-2xl font-bold">{stats.total}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Orders List */}
      <Card>
        <CardHeader>
          <CardTitle>Orders</CardTitle>
        </CardHeader>
        <CardContent>
          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList className="grid w-full grid-cols-6">
              <TabsTrigger value="pending">Pending ({stats.pending})</TabsTrigger>
              <TabsTrigger value="confirmed">Confirmed ({stats.confirmed})</TabsTrigger>
              <TabsTrigger value="dispatched">Dispatched ({stats.dispatched})</TabsTrigger>
              <TabsTrigger value="delivered">Delivered ({stats.delivered})</TabsTrigger>
              <TabsTrigger value="completed">Completed ({stats.completed})</TabsTrigger>
              <TabsTrigger value="all">All ({stats.total})</TabsTrigger>
            </TabsList>

            <TabsContent value={activeTab} className="mt-6">
              <div className="space-y-4">
                {orders.map((order) => (
                  <Card key={order.id} className="hover-lift">
                    <CardContent className="p-6">
                      <div className="flex gap-6">
                        {/* Product Image */}
                        <div className="w-20 h-20 rounded-lg overflow-hidden bg-muted flex-shrink-0">
                          {order.products?.images && order.products.images.length > 0 ? (
                            <Image
                              src={order.products.images[0]}
                              alt={order.products.title}
                              width={80}
                              height={80}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center">
                              <Package className="h-6 w-6 text-muted-foreground" />
                            </div>
                          )}
                        </div>

                        {/* Order Details */}
                        <div className="flex-1 min-w-0">
                          <div className="flex justify-between items-start mb-2">
                            <h3 className="font-semibold text-lg">
                              Order #{order.id.slice(0, 8)}
                            </h3>
                            <div className="flex gap-2">
                              {getStatusBadge(order.status)}
                              {getPaymentStatusBadge(order.payment_status)}
                            </div>
                          </div>
                          
                          <p className="text-sm text-muted-foreground mb-3">
                            {order.products?.title}
                          </p>

                          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm mb-4">
                            <div>
                              <p className="text-muted-foreground">Rental Period</p>
                              <p className="font-medium">
                                {new Date(order.rental_start_date).toLocaleDateString()} - {new Date(order.rental_end_date).toLocaleDateString()}
                              </p>
                            </div>
                            <div>
                              <p className="text-muted-foreground">Total Amount</p>
                              <p className="font-medium">₹{order.total_amount}</p>
                            </div>
                            <div>
                              <p className="text-muted-foreground">Order Date</p>
                              <p className="font-medium">
                                {new Date(order.created_at).toLocaleDateString()}
                              </p>
                            </div>
                            <div>
                              <p className="text-muted-foreground">Duration</p>
                              <p className="font-medium">{order.rental_days} days</p>
                            </div>
                          </div>

                          {/* Customer & Owner Info */}
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                            <div className="p-3 bg-muted rounded-lg">
                              <div className="flex items-center gap-2 mb-2">
                                <User className="h-4 w-4 text-muted-foreground" />
                                <span className="font-medium text-sm">Customer</span>
                              </div>
                              <div className="text-sm space-y-1">
                                <p className="font-medium">{order.customer?.full_name}</p>
                                <div className="flex items-center gap-1">
                                  <Mail className="h-3 w-3 text-muted-foreground" />
                                  <span className="text-xs">{order.customer?.email}</span>
                                </div>
                                <div className="flex items-center gap-1">
                                  <Phone className="h-3 w-3 text-muted-foreground" />
                                  <span className="text-xs">{order.customer?.phone}</span>
                                </div>
                              </div>
                            </div>

                            <div className="p-3 bg-muted rounded-lg">
                              <div className="flex items-center gap-2 mb-2">
                                <User className="h-4 w-4 text-muted-foreground" />
                                <span className="font-medium text-sm">Owner</span>
                              </div>
                              <div className="text-sm space-y-1">
                                <p className="font-medium">{order.owner?.full_name}</p>
                                <div className="flex items-center gap-1">
                                  <Mail className="h-3 w-3 text-muted-foreground" />
                                  <span className="text-xs">{order.owner?.email}</span>
                                </div>
                                <div className="flex items-center gap-1">
                                  <Phone className="h-3 w-3 text-muted-foreground" />
                                  <span className="text-xs">{order.owner?.phone}</span>
                                </div>
                              </div>
                            </div>
                          </div>

                          {/* Admin Notes */}
                          {order.admin_notes && (
                            <div className="mb-3 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                              <p className="text-sm font-medium text-blue-800 mb-1">Admin Notes</p>
                              <p className="text-sm text-blue-700">{order.admin_notes}</p>
                            </div>
                          )}

                          {/* Action Buttons */}
                          <div className="flex gap-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => setSelectedOrder(order)}
                            >
                              View Details
                            </Button>
                            
                            {getNextStatus(order.status) && (
                              <Button
                                size="sm"
                                onClick={() => handleOrderAction(order.id, getNextStatus(order.status)!)}
                              >
                                Move to {getNextStatus(order.status)}
                              </Button>
                            )}

                            {order.status === 'pending' && (
                              <Button
                                size="sm"
                                variant="destructive"
                                onClick={() => handleOrderAction(order.id, 'cancelled')}
                              >
                                Cancel Order
                              </Button>
                            )}
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}

                {orders.length === 0 && (
                  <div className="text-center py-12">
                    <Package className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                    <h3 className="text-lg font-semibold mb-2">No orders found</h3>
                    <p className="text-muted-foreground">
                      {activeTab === 'all' 
                        ? 'No orders have been placed yet.' 
                        : `No orders with status "${activeTab}" found.`
                      }
                    </p>
                  </div>
                )}
              </div>
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      {/* Order Detail Modal */}
      {selectedOrder && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <Card className="w-full max-w-4xl max-h-[90vh] overflow-y-auto">
            <CardHeader>
              <div className="flex justify-between items-center">
                <CardTitle>Order #{selectedOrder.id.slice(0, 8)}</CardTitle>
                <Button variant="ghost" size="sm" onClick={() => setSelectedOrder(null)}>
                  ×
                </Button>
              </div>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Order Status & Payment */}
              <div className="flex gap-4">
                {getStatusBadge(selectedOrder.status)}
                {getPaymentStatusBadge(selectedOrder.payment_status)}
              </div>

              {/* Product Details */}
              <div>
                <h4 className="font-semibold mb-3">Product Details</h4>
                <div className="flex gap-4">
                  <div className="w-32 h-32 rounded-lg overflow-hidden bg-muted">
                    {selectedOrder.products?.images && selectedOrder.products.images.length > 0 ? (
                      <Image
                        src={selectedOrder.products.images[0]}
                        alt={selectedOrder.products.title}
                        width={128}
                        height={128}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <Package className="h-8 w-8 text-muted-foreground" />
                      </div>
                    )}
                  </div>
                  <div className="flex-1">
                    <h5 className="font-semibold">{selectedOrder.products?.title}</h5>
                    <div className="grid grid-cols-2 gap-2 text-sm mt-2">
                      <div>
                        <p className="text-muted-foreground">Rental Price</p>
                        <p className="font-medium">₹{selectedOrder.rental_price}</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground">Security Deposit</p>
                        <p className="font-medium">₹{selectedOrder.security_deposit}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Rental Period & Amount */}
              <div>
                <h4 className="font-semibold mb-3">Rental Details</h4>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                  <div>
                    <p className="text-muted-foreground">Start Date</p>
                    <p className="font-medium">{new Date(selectedOrder.rental_start_date).toLocaleDateString()}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">End Date</p>
                    <p className="font-medium">{new Date(selectedOrder.rental_end_date).toLocaleDateString()}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Duration</p>
                    <p className="font-medium">{selectedOrder.rental_days} days</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Total Amount</p>
                    <p className="font-medium">₹{selectedOrder.total_amount}</p>
                  </div>
                </div>
              </div>

              {/* Customer & Owner Information */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h4 className="font-semibold mb-3">Customer Information</h4>
                  <div className="p-4 bg-muted rounded-lg">
                    <div className="space-y-2 text-sm">
                      <div className="flex items-center gap-2">
                        <User className="h-4 w-4 text-muted-foreground" />
                        <span className="font-medium">{selectedOrder.customer?.full_name}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Mail className="h-4 w-4 text-muted-foreground" />
                        <span>{selectedOrder.customer?.email}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Phone className="h-4 w-4 text-muted-foreground" />
                        <span>{selectedOrder.customer?.phone}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <MapPin className="h-4 w-4 text-muted-foreground" />
                        <span>{selectedOrder.customer?.city}, {selectedOrder.customer?.state}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div>
                  <h4 className="font-semibold mb-3">Owner Information</h4>
                  <div className="p-4 bg-muted rounded-lg">
                    <div className="space-y-2 text-sm">
                      <div className="flex items-center gap-2">
                        <User className="h-4 w-4 text-muted-foreground" />
                        <span className="font-medium">{selectedOrder.owner?.full_name}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Mail className="h-4 w-4 text-muted-foreground" />
                        <span>{selectedOrder.owner?.email}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Phone className="h-4 w-4 text-muted-foreground" />
                        <span>{selectedOrder.owner?.phone}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <MapPin className="h-4 w-4 text-muted-foreground" />
                        <span>{selectedOrder.owner?.city}, {selectedOrder.owner?.state}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Addresses */}
              {(selectedOrder.pickup_address || selectedOrder.delivery_address) && (
                <div>
                  <h4 className="font-semibold mb-3">Addresses</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {selectedOrder.pickup_address && (
                      <div className="p-4 bg-muted rounded-lg">
                        <div className="flex items-center gap-2 mb-2">
                          <Package className="h-4 w-4 text-muted-foreground" />
                          <span className="font-medium text-sm">Pickup Address</span>
                        </div>
                        <p className="text-sm">{selectedOrder.pickup_address}</p>
                      </div>
                    )}
                    {selectedOrder.delivery_address && (
                      <div className="p-4 bg-muted rounded-lg">
                        <div className="flex items-center gap-2 mb-2">
                          <MapPin className="h-4 w-4 text-muted-foreground" />
                          <span className="font-medium text-sm">Delivery Address</span>
                        </div>
                        <p className="text-sm">{selectedOrder.delivery_address}</p>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* Admin Actions */}
              <div>
                <h4 className="font-semibold mb-3">Admin Actions</h4>
                <div className="flex gap-2 flex-wrap">
                  {getNextStatus(selectedOrder.status) && (
                    <Button
                      onClick={() => {
                        handleOrderAction(selectedOrder.id, getNextStatus(selectedOrder.status)!)
                        setSelectedOrder(null)
                      }}
                    >
                      Move to {getNextStatus(selectedOrder.status)}
                    </Button>
                  )}
                  
                  {selectedOrder.status === 'pending' && (
                    <Button
                      variant="destructive"
                      onClick={() => {
                        handleOrderAction(selectedOrder.id, 'cancelled')
                        setSelectedOrder(null)
                      }}
                    >
                      Cancel Order
                    </Button>
                  )}

                  <Button
                    variant="outline"
                    onClick={() => {
                      const notes = prompt('Add admin notes:')
                      if (notes) {
                        // Handle adding notes
                        console.log('Adding notes:', notes)
                      }
                    }}
                  >
                    Add Notes
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}
