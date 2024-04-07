<?php

declare(strict_types=1);

namespace App\Dto;

/**
 * @template-covariant T of object
 */
interface TransformerObjectInterface extends TransformerInterface
{
    /**
     * Create DTO from object
     *
     * @return object The object.
     * @psalm-return T
     */
    public function transformFromObject($object);
}