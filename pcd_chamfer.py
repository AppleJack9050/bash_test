from pytorch3d.loss import chamfer_distance

# By default: average over points then batches
loss_chamfer, (dist_src_tgt, dist_tgt_src) = chamfer_distance(
    pc_src, pc_tgt,
    batch_reduction="mean",    # or "sum" / "none"
    point_reduction="mean"     # or "sum" / "none"
)

print(f"Chamfer loss: {loss_chamfer.item():.6f}")
# dist_src_tgt: tensor of shape (B, N) – for each src point its squared L2 to nearest tgt
# dist_tgt_src: tensor of shape (B, M) – for each tgt point its squared L2 to nearest src
