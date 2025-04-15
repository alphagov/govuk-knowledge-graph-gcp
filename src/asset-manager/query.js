db.assets.aggregate([
  {
    $project: {
      _id: true,
      created_at: true,
      updated_at: true,
      replacement_id: true,
      state: true,
      "filename_history": {
        $reduce: {
          input: {$ifNull: ["$filename_history", []]},
          initialValue: "",
          in: {$cond: [{$eq: ["$$value", ""]},"$$this",{$concat: ["$$value", ", ", "$$this"]}]}
        }
      },
      uuid: true,
      draft: true,
      redirect_url: true,
      last_modified: true,
      size: true,
      content_type: true,
      "access_limited": {
        $reduce: {
          input: {
            "$cond": {
              "if": {"$eq": [{$ifNull: ["$access_limited", []]},false]},
              "then": [],
              "else": "$access_limited"
            }
          },
          initialValue: "",
          in: {$cond: [ {$eq: ["$$value", ""]},"$$this",{$concat: ["$$value", ", ", "$$this"]}]}
        }
      },
      "access_limited_organisation_ids": {
        $reduce: {
          input: {$ifNull: ["$access_limited_organisation_ids", []]},
          initialValue: "",
          in: {$cond: [{$eq: ["$$value", ""]},"$$this",{$concat: ["$$value", ", ", "$$this"]}]}
        }
      },
      parent_document_url: true,
      deleted_at: true,
      file: true,
      _type: true,
      legacy_url_path: true
    }
  },
  {
    $out: "output"
  },
])
