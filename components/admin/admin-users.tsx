"use client"

import { useState, useEffect } from "react"
import { Users, Mail, Calendar, Loader2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { getAllUsers } from "@/lib/actions/admin"
import { SkeletonLoader } from "@/components/ui/skeleton-loader"
import { formatDate } from "@/lib/utils"

export function AdminUsers() {
  const [users, setUsers] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchUsers() {
      try {
        const { users: data, error } = await getAllUsers()
        if (error) {
          console.error("Error fetching users:", error)
        } else {
          setUsers(data || [])
        }
      } catch (error) {
        console.error("Error fetching users:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchUsers()
  }, [])

  if (loading) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="font-serif text-4xl font-bold mb-2">Users Management</h1>
          <p className="text-muted-foreground">Manage platform users</p>
        </div>
        <SkeletonLoader type="grid" count={4} />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-serif text-4xl font-bold mb-2">Users Management</h1>
        <p className="text-muted-foreground">View and manage all platform users</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-card rounded-2xl border border-border p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-primary/10 rounded-full">
              <Users className="h-6 w-6 text-primary" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Total Users</p>
              <p className="text-3xl font-bold">{users.length}</p>
            </div>
          </div>
        </div>

        <div className="bg-card rounded-2xl border border-border p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-green-500/10 rounded-full">
              <Mail className="h-6 w-6 text-green-500" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Active Users</p>
              <p className="text-3xl font-bold">{users.filter(user => user.email_confirmed_at).length}</p>
            </div>
          </div>
        </div>

        <div className="bg-card rounded-2xl border border-border p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-blue-500/10 rounded-full">
              <Calendar className="h-6 w-6 text-blue-500" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">New This Month</p>
              <p className="text-3xl font-bold">
                {users.filter(user => {
                  const userDate = new Date(user.created_at)
                  const now = new Date()
                  return userDate.getMonth() === now.getMonth() && userDate.getFullYear() === now.getFullYear()
                }).length}
              </p>
            </div>
          </div>
        </div>
      </div>

      {users.length === 0 ? (
        <div className="text-center py-20">
          <Users className="h-24 w-24 mx-auto text-muted-foreground mb-4" />
          <h3 className="font-semibold text-xl mb-2">No users found</h3>
          <p className="text-muted-foreground">No users have registered yet.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {users.map((user) => (
            <div key={user.id} className="bg-card rounded-2xl border border-border p-6">
              <div className="flex items-center gap-4">
                <Avatar className="h-12 w-12">
                  <AvatarImage src={user.avatar_url || "/placeholder.svg"} />
                  <AvatarFallback>
                    {user.full_name?.charAt(0) || user.email?.charAt(0) || "U"}
                  </AvatarFallback>
                </Avatar>

                <div className="flex-1 space-y-1">
                  <div className="flex items-center gap-2">
                    <h4 className="font-semibold text-lg">{user.full_name || "No Name"}</h4>
                    {user.is_admin && (
                      <Badge variant="default">Admin</Badge>
                    )}
                    {user.email_confirmed_at && (
                      <Badge variant="secondary">Verified</Badge>
                    )}
                  </div>
                  <p className="text-sm text-muted-foreground">{user.email}</p>
                  {user.phone && (
                    <p className="text-sm text-muted-foreground">{user.phone}</p>
                  )}
                  {user.city && user.state && (
                    <p className="text-sm text-muted-foreground">{user.city}, {user.state}</p>
                  )}
                </div>

                <div className="text-right">
                  <p className="text-sm text-muted-foreground">Joined</p>
                  <p className="text-sm font-medium">{formatDate(user.created_at)}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}