"use client"

import { useState, useEffect } from "react"
import { Star, Check, X, Loader2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { getAllReviews, approveReview, rejectReview } from "@/lib/actions/admin"
import { SkeletonLoader } from "@/components/ui/skeleton-loader"
import { formatDate } from "@/lib/utils"

export function AdminReviews() {
  const [reviews, setReviews] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [filterStatus, setFilterStatus] = useState<string>("all")

  useEffect(() => {
    async function fetchReviews() {
      try {
        const { reviews: data, error } = await getAllReviews({
          status: filterStatus !== "all" ? filterStatus : undefined,
        })
        if (error) {
          console.error("Error fetching reviews:", error)
        } else {
          setReviews(data || [])
        }
      } catch (error) {
        console.error("Error fetching reviews:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchReviews()
  }, [filterStatus])

  const handleApprove = async (reviewId: string) => {
    try {
      const { success } = await approveReview(reviewId)
      if (success) {
        setReviews(reviews.map(review => 
          review.id === reviewId ? { ...review, status: 'approved' } : review
        ))
      }
    } catch (error) {
      console.error("Error approving review:", error)
    }
  }

  const handleReject = async (reviewId: string) => {
    try {
      const { success } = await rejectReview(reviewId)
      if (success) {
        setReviews(reviews.map(review => 
          review.id === reviewId ? { ...review, status: 'rejected' } : review
        ))
      }
    } catch (error) {
      console.error("Error rejecting review:", error)
    }
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="font-serif text-4xl font-bold mb-2">Reviews Management</h1>
          <p className="text-muted-foreground">Manage and moderate product reviews</p>
        </div>
        <SkeletonLoader type="grid" count={4} />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-serif text-4xl font-bold mb-2">Reviews Management</h1>
        <p className="text-muted-foreground">Moderate and manage product reviews</p>
      </div>

      {reviews.length === 0 ? (
        <div className="text-center py-20">
          <Star className="h-24 w-24 mx-auto text-muted-foreground mb-4" />
          <h3 className="font-semibold text-xl mb-2">No reviews found</h3>
          <p className="text-muted-foreground">No reviews match the current filter.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {reviews.map((review) => (
            <div key={review.id} className="bg-card rounded-2xl border border-border p-6">
              <div className="flex items-start gap-4">
                <Avatar className="h-12 w-12">
                  <AvatarImage src={review.user?.avatar_url || "/placeholder.svg"} />
                  <AvatarFallback>
                    {review.user?.full_name?.charAt(0) || "U"}
                  </AvatarFallback>
                </Avatar>

                <div className="flex-1 space-y-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <h4 className="font-semibold text-lg">{review.user?.full_name || "Anonymous"}</h4>
                      <p className="text-sm text-muted-foreground">{review.product?.title || "Unknown Product"}</p>
                    </div>
                    <Badge 
                      variant={review.status === "approved" ? "default" : review.status === "rejected" ? "destructive" : "secondary"}
                    >
                      {review.status}
                    </Badge>
                  </div>

                  <div className="flex items-center gap-2">
                    {[...Array(5)].map((_, i) => (
                      <Star
                        key={i}
                        className={`h-4 w-4 ${
                          i < review.rating ? "text-yellow-400 fill-current" : "text-gray-300"
                        }`}
                      />
                    ))}
                    <span className="text-sm text-muted-foreground ml-2">
                      {formatDate(review.created_at)}
                    </span>
                  </div>

                  <p className="text-sm leading-relaxed">{review.comment}</p>

                  {review.status === "pending" && (
                    <div className="flex gap-2 pt-2">
                      <Button
                        size="sm"
                        onClick={() => handleApprove(review.id)}
                        className="bg-green-600 hover:bg-green-700"
                      >
                        <Check className="h-4 w-4 mr-1" />
                        Approve
                      </Button>
                      <Button
                        size="sm"
                        variant="destructive"
                        onClick={() => handleReject(review.id)}
                      >
                        <X className="h-4 w-4 mr-1" />
                        Reject
                      </Button>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}