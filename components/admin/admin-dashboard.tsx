"use client"

import { useState } from "react"
import { LayoutDashboard, Star, Users, Package, Truck, FileText, Image as ImageIcon, LogOut, ClipboardList, ShoppingCart } from "lucide-react"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { AdminOverview } from "@/components/admin/admin-overview"
import { AdminReviews } from "@/components/admin/admin-reviews"
import { AdminUsers } from "@/components/admin/admin-users"
import { AdminProducts } from "@/components/admin/admin-products"
import { AdminOrders } from "@/components/admin/admin-orders"
import { AdminContent } from "@/components/admin/admin-content"
import { AdminProductManagement } from "@/components/admin/admin-product-management"
import { AdminOrderManagement } from "@/components/admin/admin-order-management"
import { AdminUserManagement } from "@/components/admin/admin-user-management"
import { Button } from "@/components/ui/button"
import Image from "next/image"
import Link from "next/link"

export function AdminDashboard() {
  const [activeTab, setActiveTab] = useState("dashboard")

  return (
    <div className="min-h-screen bg-muted/30">
      {/* Admin Header */}
      <header className="sticky top-0 z-50 w-full border-b border-border bg-background/95 backdrop-blur">
        <div className="container mx-auto px-4">
          <div className="flex h-16 items-center justify-between">
            <div className="flex items-center gap-4">
              <Image
                src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Colour%20Logo%20With%20Black%20BG-tkgKC6mQgEtBgSkwsc6O0LPOZiRJsS.png"
                alt="Rentimade"
                width={120}
                height={40}
                className="h-8 w-auto"
              />
              <span className="text-sm font-medium text-muted-foreground">Admin Panel</span>
            </div>
            <Button variant="outline" size="sm" className="bg-transparent">
              <LogOut className="h-4 w-4 mr-2" />
              Logout
            </Button>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="grid w-full grid-cols-2 md:grid-cols-8 bg-muted h-auto mb-8">
            <TabsTrigger value="dashboard" className="flex items-center gap-2 py-3">
              <LayoutDashboard className="h-4 w-4" />
              <span className="hidden sm:inline">Dashboard</span>
            </TabsTrigger>
            <TabsTrigger value="product-management" className="flex items-center gap-2 py-3">
              <ClipboardList className="h-4 w-4" />
              <span className="hidden sm:inline">Product Review</span>
            </TabsTrigger>
            <TabsTrigger value="order-management" className="flex items-center gap-2 py-3">
              <ShoppingCart className="h-4 w-4" />
              <span className="hidden sm:inline">Order Track</span>
            </TabsTrigger>
            <TabsTrigger value="reviews" className="flex items-center gap-2 py-3">
              <Star className="h-4 w-4" />
              <span className="hidden sm:inline">Reviews</span>
            </TabsTrigger>
            <TabsTrigger value="user-management" className="flex items-center gap-2 py-3">
              <Users className="h-4 w-4" />
              <span className="hidden sm:inline">User Mgmt</span>
            </TabsTrigger>
            <TabsTrigger value="products" className="flex items-center gap-2 py-3">
              <Package className="h-4 w-4" />
              <span className="hidden sm:inline">Products</span>
            </TabsTrigger>
            <TabsTrigger value="orders" className="flex items-center gap-2 py-3">
              <Truck className="h-4 w-4" />
              <span className="hidden sm:inline">Orders</span>
            </TabsTrigger>
            <TabsTrigger value="content" className="flex items-center gap-2 py-3">
              <FileText className="h-4 w-4" />
              <span className="hidden sm:inline">Content</span>
            </TabsTrigger>
          </TabsList>

          <TabsContent value="dashboard">
            <AdminOverview />
          </TabsContent>

          <TabsContent value="product-management">
            <AdminProductManagement />
          </TabsContent>

          <TabsContent value="order-management">
            <AdminOrderManagement />
          </TabsContent>

          <TabsContent value="reviews">
            <AdminReviews />
          </TabsContent>

          <TabsContent value="user-management">
            <AdminUserManagement />
          </TabsContent>

          <TabsContent value="products">
            <AdminProducts />
          </TabsContent>

          <TabsContent value="orders">
            <AdminOrders />
          </TabsContent>

          <TabsContent value="content">
            <AdminContent />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}
