"use client"

import { useState } from "react"
import { Header } from "@/components/header"
import { Footer } from "@/components/footer"
import { ImageUpload } from "@/components/ui/image-upload"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

export default function TestUploadPage() {
  const [images, setImages] = useState<string[]>([])
  const [uploading, setUploading] = useState(false)

  const handleTestUpload = async () => {
    if (images.length === 0) {
      alert("Please upload at least one image first")
      return
    }

    setUploading(true)
    try {
      // Simulate sending images to server
      await new Promise(resolve => setTimeout(resolve, 1000))
      alert(`Successfully uploaded ${images.length} image(s)!`)
      console.log("Uploaded images:", images)
    } catch (error) {
      alert("Upload failed")
    } finally {
      setUploading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <main className="flex-1">
        <div className="container mx-auto px-4 py-8">
          <Card className="max-w-2xl mx-auto">
            <CardHeader>
              <CardTitle>Test Cloudinary Image Upload</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <ImageUpload
                images={images}
                onImagesChange={setImages}
                maxImages={5}
              />
              
              {images.length > 0 && (
                <div className="space-y-4">
                  <h3 className="font-semibold">Uploaded Images:</h3>
                  <div className="grid grid-cols-2 gap-4">
                    {images.map((image, index) => (
                      <div key={index} className="space-y-2">
                        <img
                          src={image}
                          alt={`Upload ${index + 1}`}
                          className="w-full h-32 object-cover rounded-lg border"
                        />
                        <p className="text-xs text-muted-foreground truncate">
                          {image}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              <Button
                onClick={handleTestUpload}
                disabled={uploading || images.length === 0}
                className="w-full"
              >
                {uploading ? "Testing..." : "Test Upload"}
              </Button>
            </CardContent>
          </Card>
        </div>
      </main>
      <Footer />
    </div>
  )
}
