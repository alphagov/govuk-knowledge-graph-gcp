db.assets.aggregate([
  {
    $project: {
      md5_hexdigest: false,
      etag: false,
      auth_bypass_ids: false,
    }
  },
  {
    $out: "output"
  },
])
