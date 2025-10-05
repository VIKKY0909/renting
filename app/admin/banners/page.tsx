"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Plus, Edit, Trash2, Eye, EyeOff, Upload, Save, X } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { useAuth } from "@/lib/auth-context"
import { toast } from "sonner"

interface Banner {
  id: string
  title: string
  subtitle?: string
  description?: string
  button_text?: string
  button_link?: string
  image_url: string
  gradient_from: string
  gradient_to: string
  gradient_via: string
  is_active: boolean
  sort_order: number
  category_id?: string
  banner_categories?: {
    id: string
    name: string
    description?: string
  }
  created_at: string
  updated_at: string
}

interface BannerCategory {
  id: string
  name: string
  description?: string
}

export default function AdminBannersPage() {
  const { user, profile } = useAuth()
  const router = useRouter()
  const [banners, setBanners] = useState<Banner[]>([])
  const [categories, setCategories] = useState<BannerCategory[]>([])
  const [loading, setLoading] = useState(true)
  const [isEditing, setIsEditing] = useState(false)
  const [editingBanner, setEditingBanner] = useState<Banner | null>(null)
  const [isCreating, setIsCreating] = useState(false)

  // Redirect if not admin
  useEffect(() => {
    if (profile && !profile.is_admin) {
      router.push('/')
      toast.error('Admin access required')
    }
  }, [profile, router])

  // Fetch banners and categories
  useEffect(() => {
    if (profile?.is_admin) {
      fetchBanners()
      fetchCategories()
    }
  }, [profile])

  const fetchBanners = async () => {
    try {
      const response = await fetch('/api/banners?admin=true')
      const data = await response.json()
      if (response.ok) {
        setBanners(data.banners || [])
      } else {
        toast.error('Failed to fetch banners')
      }
    } catch (error) {
      console.error('Error fetching banners:', error)
      toast.error('Error fetching banners')
    } finally {
      setLoading(false)
    }
  }

  const fetchCategories = async () => {
    try {
      const response = await fetch('/api/banner-categories')
      const data = await response.json()
      if (response.ok) {
        setCategories(data.categories || [])
      }
    } catch (error) {
      console.error('Error fetching categories:', error)
    }
  }

  const handleCreateBanner = () => {
    setEditingBanner({
      id: '',
      title: '',
      subtitle: '',
      description: '',
      button_text: '',
      button_link: '',
      image_url: '',
      gradient_from: '#ff6b9d',
      gradient_to: '#c44569',
      gradient_via: '#f8b500',
      is_active: true,
      sort_order: banners.length,
      category_id: '',
      created_at: '',
      updated_at: ''
    })
    setIsCreating(true)
    setIsEditing(true)
  }

  const handleEditBanner = (banner: Banner) => {
    setEditingBanner(banner)
    setIsCreating(false)
    setIsEditing(true)
  }

  const handleSaveBanner = async () => {
    if (!editingBanner) return

    try {
      const url = isCreating ? '/api/banners' : `/api/banners/${editingBanner.id}`
      const method = isCreating ? 'POST' : 'PUT'

      const response = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(editingBanner)
      })

      if (response.ok) {
        toast.success(isCreating ? 'Banner created successfully' : 'Banner updated successfully')
        fetchBanners()
        setIsEditing(false)
        setEditingBanner(null)
      } else {
        const error = await response.json()
        toast.error(error.error || 'Failed to save banner')
      }
    } catch (error) {
      console.error('Error saving banner:', error)
      toast.error('Error saving banner')
    }
  }

  const handleDeleteBanner = async (id: string) => {
    if (!confirm('Are you sure you want to delete this banner?')) return

    try {
      const response = await fetch(`/api/banners/${id}`, {
        method: 'DELETE'
      })

      if (response.ok) {
        toast.success('Banner deleted successfully')
        fetchBanners()
      } else {
        const error = await response.json()
        toast.error(error.error || 'Failed to delete banner')
      }
    } catch (error) {
      console.error('Error deleting banner:', error)
      toast.error('Error deleting banner')
    }
  }

  const handleToggleActive = async (banner: Banner) => {
    try {
      const response = await fetch(`/api/banners/${banner.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...banner, is_active: !banner.is_active })
      })

      if (response.ok) {
        toast.success(`Banner ${!banner.is_active ? 'activated' : 'deactivated'}`)
        fetchBanners()
      } else {
        const error = await response.json()
        toast.error(error.error || 'Failed to update banner')
      }
    } catch (error) {
      console.error('Error toggling banner:', error)
      toast.error('Error updating banner')
    }
  }

  const handleImageUpload = async (file: File) => {
    try {
      const formData = new FormData()
      formData.append('file', file)

      const response = await fetch('/api/upload-image', {
        method: 'POST',
        body: formData
      })

      if (response.ok) {
        const data = await response.json()
        setEditingBanner(prev => prev ? { ...prev, image_url: data.url } : null)
        toast.success('Image uploaded successfully')
      } else {
        toast.error('Failed to upload image')
      }
    } catch (error) {
      console.error('Error uploading image:', error)
      toast.error('Error uploading image')
    }
  }

  if (!profile?.is_admin) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-red-600">Access Denied</h1>
          <p className="text-muted-foreground">Admin access required</p>
        </div>
      </div>
    )
  }

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
          <p className="mt-2 text-muted-foreground">Loading banners...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold gradient-text">Banner Management</h1>
          <p className="text-muted-foreground">Manage homepage banners and promotional content</p>
        </div>
        <Button onClick={handleCreateBanner} className="btn-luxury">
          <Plus className="h-4 w-4 mr-2" />
          Create Banner
        </Button>
      </div>

      {/* Banner Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        {banners.map((banner) => (
          <Card key={banner.id} className="overflow-hidden hover-lift">
            <div className="relative h-48 bg-cover bg-center" style={{ backgroundImage: `url(${banner.image_url})` }}>
              <div className="absolute top-2 right-2 flex gap-2">
                <Badge variant={banner.is_active ? "default" : "secondary"}>
                  {banner.is_active ? <Eye className="h-3 w-3 mr-1" /> : <EyeOff className="h-3 w-3 mr-1" />}
                  {banner.is_active ? 'Active' : 'Inactive'}
                </Badge>
              </div>
              <div className="absolute bottom-2 left-2">
                <Badge variant="outline" className="bg-white/80 text-black">
                  #{banner.sort_order}
                </Badge>
              </div>
            </div>
            <CardHeader>
              <CardTitle className="text-lg">{banner.title}</CardTitle>
              {banner.subtitle && (
                <p className="text-sm text-muted-foreground">{banner.subtitle}</p>
              )}
              {banner.banner_categories && (
                <Badge variant="secondary">{banner.banner_categories.name}</Badge>
              )}
            </CardHeader>
            <CardContent>
              <div className="flex gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleEditBanner(banner)}
                  className="flex-1"
                >
                  <Edit className="h-3 w-3 mr-1" />
                  Edit
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleToggleActive(banner)}
                  className="flex-1"
                >
                  {banner.is_active ? <EyeOff className="h-3 w-3 mr-1" /> : <Eye className="h-3 w-3 mr-1" />}
                  {banner.is_active ? 'Hide' : 'Show'}
                </Button>
                <Button
                  size="sm"
                  variant="destructive"
                  onClick={() => handleDeleteBanner(banner.id)}
                >
                  <Trash2 className="h-3 w-3" />
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Edit/Create Modal */}
      {isEditing && editingBanner && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <CardHeader>
              <div className="flex justify-between items-center">
                <CardTitle>{isCreating ? 'Create Banner' : 'Edit Banner'}</CardTitle>
                <Button variant="ghost" size="sm" onClick={() => setIsEditing(false)}>
                  <X className="h-4 w-4" />
                </Button>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Basic Info */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="title">Title *</Label>
                  <Input
                    id="title"
                    value={editingBanner.title}
                    onChange={(e) => setEditingBanner(prev => prev ? { ...prev, title: e.target.value } : null)}
                    placeholder="Banner title"
                  />
                </div>
                <div>
                  <Label htmlFor="subtitle">Subtitle</Label>
                  <Input
                    id="subtitle"
                    value={editingBanner.subtitle}
                    onChange={(e) => setEditingBanner(prev => prev ? { ...prev, subtitle: e.target.value } : null)}
                    placeholder="Banner subtitle"
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  value={editingBanner.description}
                  onChange={(e) => setEditingBanner(prev => prev ? { ...prev, description: e.target.value } : null)}
                  placeholder="Banner description"
                  rows={3}
                />
              </div>

              {/* Button Info */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="button_text">Button Text</Label>
                  <Input
                    id="button_text"
                    value={editingBanner.button_text}
                    onChange={(e) => setEditingBanner(prev => prev ? { ...prev, button_text: e.target.value } : null)}
                    placeholder="e.g., Shop Now"
                  />
                </div>
                <div>
                  <Label htmlFor="button_link">Button Link</Label>
                  <Input
                    id="button_link"
                    value={editingBanner.button_link}
                    onChange={(e) => setEditingBanner(prev => prev ? { ...prev, button_link: e.target.value } : null)}
                    placeholder="/browse"
                  />
                </div>
              </div>

              {/* Image Upload */}
              <div>
                <Label htmlFor="image">Banner Image *</Label>
                <div className="flex gap-2">
                  <Input
                    id="image"
                    value={editingBanner.image_url}
                    onChange={(e) => setEditingBanner(prev => prev ? { ...prev, image_url: e.target.value } : null)}
                    placeholder="Image URL"
                  />
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(e) => {
                      const file = e.target.files?.[0]
                      if (file) handleImageUpload(file)
                    }}
                    className="hidden"
                    id="upload"
                  />
                  <Label htmlFor="upload" asChild>
                    <Button variant="outline" size="sm">
                      <Upload className="h-4 w-4 mr-1" />
                      Upload
                    </Button>
                  </Label>
                </div>
              </div>

              {/* Gradient Colors */}
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <Label htmlFor="gradient_from">Gradient From</Label>
                  <div className="flex gap-2">
                    <Input
                      id="gradient_from"
                      value={editingBanner.gradient_from}
                      onChange={(e) => setEditingBanner(prev => prev ? { ...prev, gradient_from: e.target.value } : null)}
                      placeholder="#ff6b9d"
                    />
                    <input
                      type="color"
                      value={editingBanner.gradient_from}
                      onChange={(e) => setEditingBanner(prev => prev ? { ...prev, gradient_from: e.target.value } : null)}
                      className="w-12 h-10 border rounded"
                    />
                  </div>
                </div>
                <div>
                  <Label htmlFor="gradient_via">Gradient Via</Label>
                  <div className="flex gap-2">
                    <Input
                      id="gradient_via"
                      value={editingBanner.gradient_via}
                      onChange={(e) => setEditingBanner(prev => prev ? { ...prev, gradient_via: e.target.value } : null)}
                      placeholder="#f8b500"
                    />
                    <input
                      type="color"
                      value={editingBanner.gradient_via}
                      onChange={(e) => setEditingBanner(prev => prev ? { ...prev, gradient_via: e.target.value } : null)}
                      className="w-12 h-10 border rounded"
                    />
                  </div>
                </div>
                <div>
                  <Label htmlFor="gradient_to">Gradient To</Label>
                  <div className="flex gap-2">
                    <Input
                      id="gradient_to"
                      value={editingBanner.gradient_to}
                      onChange={(e) => setEditingBanner(prev => prev ? { ...prev, gradient_to: e.target.value } : null)}
                      placeholder="#c44569"
                    />
                    <input
                      type="color"
                      value={editingBanner.gradient_to}
                      onChange={(e) => setEditingBanner(prev => prev ? { ...prev, gradient_to: e.target.value } : null)}
                      className="w-12 h-10 border rounded"
                    />
                  </div>
                </div>
              </div>

              {/* Settings */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="sort_order">Sort Order</Label>
                  <Input
                    id="sort_order"
                    type="number"
                    value={editingBanner.sort_order}
                    onChange={(e) => setEditingBanner(prev => prev ? { ...prev, sort_order: parseInt(e.target.value) || 0 } : null)}
                  />
                </div>
                <div>
                  <Label htmlFor="category">Category</Label>
                  <select
                    id="category"
                    value={editingBanner.category_id}
                    onChange={(e) => setEditingBanner(prev => prev ? { ...prev, category_id: e.target.value } : null)}
                    className="w-full p-2 border rounded-md"
                  >
                    <option value="">Select Category</option>
                    {categories.map((category) => (
                      <option key={category.id} value={category.id}>
                        {category.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Preview */}
              {editingBanner.image_url && (
                <div>
                  <Label>Preview</Label>
                  <div 
                    className="h-32 bg-cover bg-center rounded-md relative"
                    style={{ backgroundImage: `url(${editingBanner.image_url})` }}
                  >
                    <div 
                      className="absolute inset-0 rounded-md"
                      style={{
                        background: `linear-gradient(135deg, ${editingBanner.gradient_from}20, ${editingBanner.gradient_via}20, ${editingBanner.gradient_to}20)`
                      }}
                    />
                    <div className="absolute bottom-2 left-2 text-white">
                      <div className="font-bold">{editingBanner.title}</div>
                      {editingBanner.subtitle && (
                        <div className="text-sm opacity-90">{editingBanner.subtitle}</div>
                      )}
                    </div>
                  </div>
                </div>
              )}

              {/* Actions */}
              <div className="flex gap-2 pt-4">
                <Button onClick={handleSaveBanner} className="btn-luxury flex-1">
                  <Save className="h-4 w-4 mr-2" />
                  {isCreating ? 'Create Banner' : 'Update Banner'}
                </Button>
                <Button variant="outline" onClick={() => setIsEditing(false)}>
                  Cancel
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}
