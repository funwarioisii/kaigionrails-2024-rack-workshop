class App
  def call(env)
    method = env["REQUEST_METHOD"]
    path = env["PATH_INFO"]

    if path == '/'
      return [
        200,
        {},
        ["It works"],
      ]
    end

    slug = path.split('/hello/').last
    return [
      200,
      {},
      ["Hello #{slug}"]
    ]

  end
end

run App.new
