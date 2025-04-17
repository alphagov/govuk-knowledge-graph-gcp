db.assets.aggregate([
  {
    $project: {
      _id: { $toString: "$_id" },
      created_at: { $toString: "$created_at" },
      updated_at: { $toString: "$updated_at" },
      replacement_id: { $toString: "$replacement_id" },
      state: true,
      filename_history: true,
      uuid: true,
      draft: true,
      redirect_url: true,
      last_modified: { $toString: "$last_modified" },
      size: true,
      content_type: true,
      access_limited: {
        $cond: {
          if: { $eq: ["$access_limited", false] },
          then: [],
          else: "$access_limited"
        }
      },
      access_limited_organisation_ids: true,
      parent_document_url: true,
      deleted_at: { $toString: "$deleted_at" },
      file: true,
      _type: true,
      legacy_url_path: true
    }
  },
  {
    $out: "output"
  },
])
