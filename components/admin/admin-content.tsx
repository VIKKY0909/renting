"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Plus, Edit, Trash2, Loader2 } from "lucide-react"
import { getAllFAQs } from "@/lib/actions/admin"
import { SkeletonLoader } from "@/components/ui/skeleton-loader"

export function AdminContent() {
  const [faqs, setFAQs] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchFAQs() {
      try {
        const { faqs: data, error } = await getAllFAQs()
        if (error) {
          console.error("Error fetching FAQs:", error)
        } else {
          setFAQs(data || [])
        }
      } catch (error) {
        console.error("Error fetching FAQs:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchFAQs()
  }, [])

  if (loading) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="font-serif text-4xl font-bold mb-2">Content Management</h1>
          <p className="text-muted-foreground">Manage testimonials and FAQs</p>
        </div>
        <SkeletonLoader type="grid" count={4} />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-serif text-4xl font-bold mb-2">Content Management</h1>
        <p className="text-muted-foreground">Manage testimonials and FAQs</p>
      </div>

      <Tabs defaultValue="faqs" className="w-full">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="faqs">FAQs</TabsTrigger>
          <TabsTrigger value="testimonials">Testimonials</TabsTrigger>
        </TabsList>

        <TabsContent value="faqs" className="space-y-4">
          <div className="flex justify-between items-center">
            <h2 className="text-2xl font-semibold">Frequently Asked Questions</h2>
            <Button className="bg-primary text-primary-foreground hover:bg-primary/90">
              <Plus className="h-4 w-4 mr-2" />
              Add FAQ
            </Button>
          </div>

          {faqs.length === 0 ? (
            <div className="text-center py-20">
              <p className="text-muted-foreground">No FAQs found. Add some to get started.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {faqs.map((faq) => (
                <div key={faq.id} className="bg-card rounded-2xl border border-border p-6">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <h3 className="font-semibold text-lg mb-2">{faq.question}</h3>
                      <p className="text-muted-foreground mb-2">{faq.answer}</p>
                      <div className="flex items-center gap-2">
                        <span className="text-xs bg-muted px-2 py-1 rounded">{faq.category}</span>
                        <span className="text-xs text-muted-foreground">Order: {faq.order_index}</span>
                        <span className={`text-xs px-2 py-1 rounded ${
                          faq.is_published ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                        }`}>
                          {faq.is_published ? 'Published' : 'Draft'}
                        </span>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <Button variant="outline" size="sm">
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button variant="outline" size="sm" className="text-destructive hover:text-destructive">
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </TabsContent>

        <TabsContent value="testimonials" className="space-y-4">
          <div className="flex justify-between items-center">
            <h2 className="text-2xl font-semibold">Customer Testimonials</h2>
            <Button className="bg-primary text-primary-foreground hover:bg-primary/90">
              <Plus className="h-4 w-4 mr-2" />
              Add Testimonial
            </Button>
          </div>

          <div className="text-center py-20">
            <p className="text-muted-foreground">Testimonials management coming soon.</p>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}